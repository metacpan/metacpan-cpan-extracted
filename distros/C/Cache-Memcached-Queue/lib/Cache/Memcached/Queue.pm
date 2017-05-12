#! /usr/bin/perl

package Cache::Memcached::Queue;
use Moose;
use Carp qw/confess cluck/;
use feature qw/say switch/;
use Cache::Memcached::Fast;
use Data::Serializer;
use Data::Dumper;

BEGIN {
  our $VERSION = '0.1.8';
}

has config_file => ( is => 'rw' );

has memcached => ( is => 'rw' );

has 'last' => ( is => 'rw' );

has first => ( is => 'rw' );

has memcached_servers => (
  is  => 'rw',
  isa => 'Cache::Memcached'
);

has name => ( is => 'rw',
          isa => 'Str',
          default => 'CMQID' );

has id => (
  is     => 'rw',
  required => 'id'
);


has qid => (
  is  => 'rw',
  isa => 'Str',
);

has max_enq => (
  is    => 'rw',
  default => 0,
);

has servers => (
  is    => 'rw',
  default => sub { return ['localhost:11211'] },
);

has size => ( is => 'rw' );

has serialize => (
  is    => 'rw',
  isa   => 'Int',
  default => 0,
);

has serializer => (
  is    => 'rw',
  default => sub {
    return Data::Serializer->new(
        serializer => 'Storable',
        compress   => 1,
    );
  }
);









sub BUILD {
  my ( $self, ) = @_;
  $self->memcached(
    Cache::Memcached::Fast->new( { servers => $self->servers } ) )
  or confess "Can't load from memcached!";
  my $name = $self->name;
  $name .= '_' if $name !~ /\_$/;
  $self->qid($name . $self->id);
  undef $name;
  $self->load;
  return $self;
}








sub load {
  my ($self,$flag) = @_;
  $flag = 0 if !defined($flag);
  my ( $ok, $id ) = ( 0, $self->id );
  if ( !defined($id) || !$id ) {
    confess "You must define an id!";
  }
  else {
    $id .= '_' if $id !~ /\_$/;
    my $qid = $self->name . '_' . $self->id . '_';
    $self->qid($qid);
    my ( $first, $last, $size, $name ) =
      ( $qid . 'first', $qid . 'last', $qid . 'size', $qid . 'name',  );

    #This queue already exists?
    my $real_first = $self->memcached->get($first);
    confess "Fatal error! Can't load or create queue! Check memcached server!" if $flag and !defined($real_first);
    if ( defined($real_first) ) {
      $self->first( $self->memcached->get($first) );
      $self->last( $self->memcached->get($last) );
      $self->size( $self->memcached->get($size) );
      $self->name( $self->memcached->get($name) ) if !defined $self->name;
      $self->qid($qid);
      $ok = 1;
    }
    else {
      say q[Queue '] . $self->qid . q[' doesn't exists! Creating...];
      $self->memcached->set($qid . 'LOCKED',$$,0);
      $self->memcached->set($name,$self->name,0);
      $self->memcached->set($first,$self->qid . '1',0,0);
      $self->memcached->set($last,$self->qid . '1',0,0);
      $self->memcached->set($size,0,0);
      $self->memcached->set($qid . 'LOCKED',0,0);
      say q[Queue '] . $self->qid . q[' was created!];
      $self->load(1);
    }
  }
  return $ok;
}








sub enq {
  my ( $self, $parameters ) = @_;
  my ( $ok, $expire, ) = ( 0, undef, undef );
  if(!defined($parameters)){
    say 'No value was defined to enqueue!';
  }
  else {
    my $value = undef;
    if(ref($parameters) eq ''){
      $value = $parameters // '';
    }
    elsif(!defined($parameters->{value})){
      $value = $parameters || '';
    }
    else {
      $value = $parameters->{value} || '';
    }

    #checar se é necessário a serialização
    if(ref($value)){
      #serializar
      my $serialized = $self->serializer->serialize($value);
      $value = $serialized;
      undef $serialized;
    }
    $self->load;
    if(!$self->_is_locked || $self->_unlock){
      $self->_lock;
      my $size = $self->size // 0;
      #checando se a fila esta cheia
      if($self->max_enq > 0 && $self->size >= $self->max_enq){
        say "Queue is full!";
      }
      else {
        my $last = $1 if $self->last =~ /_(\d+)$/ // 1;
        #checando se last == first e se existe algum valor
        my $first_value = $self->memcached->get($self->first);
        if( $first_value) {
          $last++;
        }
        $size++;
        my $new_last = $self->qid . $last;
        $self->last($new_last);
  
        $self->memcached->set($new_last,$value,0);
      }
      $self->size($size);
      $self->_save(['last','size']);
      $self->_unlock if($self->_is_locked);
    }
  }
  return $ok;
}







sub deq {
  my ( $self, ) = @_;
  my ( $last_item,$value ) = ( undef,undef );
  $self->load;
  if(!$self->_is_locked || $self->_unlock ){
    $self->_lock;
    my $size = $self->size;
    if(!$size){
      say 'Queue is empty!';
    }
    else { 
      my $first = $1 if $self->first =~ /_(\d+)$/ // 1;
      $value = $self->memcached->get($self->first) // '';
      if($value =~ /^\^.*?Storable/i){
        my $unserialized = $self->serializer->deserialize($value);
        $value = $unserialized;
        undef $unserialized;
      }
      $self->memcached->delete($self->first);
      if($self->last ne $self->first){
        $first++;
        $self->first($self->qid . $first);
        $size-- if($size > 0);
      }
      else {
        $size = 0;
        $self->first($self->qid . '1',0);
        $self->last($self->qid . '1',0);
        $self->_save(['last']);
      }
    }
    $self->size($size);
    $self->_save(['first','size']);
    $self->_unlock if($self->_is_locked);
  }
  return $value // '';
}






sub show {
  my ( $self, ) = @_;
  while(!$self->_lock){
    $self->load;
    sleep .3;
  }
  my $first = $1 if $self->first =~ /_(\d+)$/ // 1;
  my $last = $1 if $self->last =~ /_(\d+)$/ // 1;
  foreach my $i($first..$last){
    my $value = $self->memcached->get($self->qid . $i);
    say "$i - $value";
  } 
  $self->_unlock;
}





sub cleanup {
  my ( $self, ) = @_;
  $self->load;
  $self->iterate(sub {
                  my $index = shift;
                  $self->memcached->delete($index);
                });
}





sub _save {
  my ( $self, $parameters ) = @_;
  my $last = $self->last;
  my $ok   = 0;

  if ( ref($parameters) !~ /ARRAY/ ) {
    confess "The parameters to save data MUST BE AN ARRAYREF";
  }
  foreach my $k ( @{$parameters} ) {
    if ( $k !~ /^name|first|last|size|max_enq|qid$/ ) {
        confess "The parameter '$k' is invalid!";
    }
    else {
      my $index = $self->qid . $k;
      if ( !$self->memcached->set( $index, $self->{$k},0 ) ) {
        confess "Memcached can't set a value!";
      }
      else {
        $ok = 1;
      }
    }
  }
  return $ok;
}





sub iterate {
  my ( $self, $action, $action_params ) = @_;
  $self->load;
  if( (!defined($action) || !$action ) ||  
    (defined($action) && ref($action) !~ /CODE/)
  ){
    confess "'action' MUST be a CODE reference!";
  }
  elsif(defined($action_params) && ref($action_params) !~ /ARRAY/){
    confess "'action_parameters' MUST be Array"; 
  }
  elsif($self->size == 0){
    say STDERR "Queue '" . $self->qid . "' is empty!";
  }
  else {
    my $first_index = $1 if $self->first =~ /(\d+)$/;
	my $last_index = $1 if $self->last =~ /(\d+)$/;
    say "The queue is " . $self->name;
	foreach my $i($first_index .. $last_index){
      #mounting index for memcached
      my $mc_index = $self->qid;
      $mc_index .= '_' if $mc_index !~ /_$/;
      $mc_index .= $i;
      my $value = $self->memcached->get($mc_index);
      if(!defined($value)){
        confess "An error occured trying make a 'get' operation. No value found for '$mc_index' index";
      }
      $action->($mc_index,$value,$action_params);
    }
  }
}







sub _lock {
  my ($self,$pid,$lock_pid) = (shift,$$,0);
  $self->load;
  my $qid = $self->qid;
  confess "Panic! No 'qid'!" if (!defined($qid) || !$qid);
  my $lock_idx = $qid . 'LOCKED';
  $lock_pid = $self->_is_locked($lock_idx);
  if(!$lock_pid){
    my $rs = $self->memcached->set($lock_idx,$pid,0);
    confess "Memcached server can't write!" if !defined($rs);
    $lock_pid = $pid;
  }
  else {
    say "is already locked!";
    $lock_pid = 0;
  }
  $self->load;
  return $lock_pid || 0;
}






sub _unlock {
  my ($self,$pid,$ok) = (shift,$$,0);
  $self->load;
  my $qid = $self->qid;
  confess "Panic! No 'qid'!" if (!defined($qid) || !$qid);
  my $lock_idx = $qid . 'LOCKED';
  my $lock_pid = $self->_is_locked($lock_idx);
  if($lock_pid && $lock_pid == $pid){
    my $rs = $self->memcached->set($lock_idx,0,0);
    confess "Memcached can't write!" if !defined($rs);
    $ok = 1;
  }
  elsif($lock_pid && $lock_pid != $pid){
    say "Is locked by another process! $lock_pid";

  }
  $self->load;
  return $ok;
}






sub _is_locked {
  my ($self,$lock_idx) = @_;
  $lock_idx = 0 if !defined $lock_idx;
  my $found = 0;

#  confess "Parameter 'lock_idx' is mandatory!" if (!defined($lock_idx) || !$lock_idx);
  if(!defined($lock_idx) || !$lock_idx){
    $lock_idx = $self->qid . 'LOCKED';
  }
  my $lock_pid = $self->memcached->get($lock_idx); #this pid locked the queue!
#  $lock_pid = 0 if $$ == $lock_pid;
#  foreach my $p(@{$t->table}){
#    if($p->pid == $lock_pid){
#      $found = $p->pid;
#      last;
#    }
#  }
#  $lock_pid = 0 if !$found;
  return $lock_pid ;
}





__PACKAGE__->meta->make_immutable;

=head1 NAME

 Cache::Memcached::Queue - Simple and elegant way to persist queues on Memcached 

=head1 VERSION

 Version 0.1.8

 unstable version

=cut

=head1 DESCRIPTION

The idea is take advantage from Cache::Memcached::Fast module using it as a back-end for
queue structures without sockets, extra protocols or extra databases to maintain queues-metadata.
All stuff is stored on Memcached! Including metadata.


This can be done adding some metadata on Memcached hash structure that controls data on 
a queue structure(strict FIFO). This metadata defines identification for queues and 
controls first element, last element, size(number of elements) and lock information 
following patterns in their names. For stabilish this patterns, it's necessary to define 
some elements:

=over

=item * prefix - WARNING! This attribute is deprecated!!! DON'T USE IT! 

=item * index - WARNING! This attribute is deprecated! DON'T USE IT!

=item * name - This is a 'string' that defines a name for your queue;

=item * id - It's a unique identifier for your queue and is defined on the 'id' attribute.
        You can have queues with the same name since you have different ids;



=back



=head1 SYNOPSIS

  use common::sense;
  use Cache::Memcached::Queue;
  my $q = Cache::Memcached::Queue->new(   
          name => 'foo', 
          id => 1,
          servers => ['localhost:11211'], #This is default. RTFM ON Cache::Memcached::Fast for more options
          serialize => 1, #if true, every value on enq will be serialized (Data::Serializer with Storable)
                          #but if complex data is passed(hashes, arrays, objects, etc), this data will be
                          #serialized even serialize attribute is false.
         );  

  
  #loading queue  
  $q->load();#load data from Memcached

  #common operations...
  $q->enq('fus'); #enqueue 'fus'. 

  $q->enq('goh'); #enqueue 'goh' and this never expires on memcached 

  $q->show; #show all items from queue. In this case: 'goh'. Remember... FIFO(First In First Out).

  $q->deq; #deqeue 'fus'. 

  $q->show; #show all items from queue. In this case: 'nuke'(first and last element from queue).

  $q->enq({'fus'=>['goh','dah']}); #enqueue serialize and compact data.

  $q->cleanup; #cleans everything. From object and from Memcached.

  

=head2 load()

Try to load the queue metadata from Memcached. If works, will return true. Otherwise 
will return false.


=head2 enq( HashRef $parameters or SCALAR $value )

Try to make a 'enqueue' operation. You can enqueue scalar or complex data(hashes, arrays, objects etc). 

There is two ways to enqueue:

=over

=item * common way(RECOMMENDED): 

  my $Bar = 'Bar';
  my @Array = ('Foo','Bar');
  my %Hash = ('Foo' => 'Bar');
  $q->enq('Foo');
  $q->enq($Bar);
  $q->enq(\@MyArray);
  $q->enq(\%MyHash); #since %MyHash doesn't have 'value' and/or 'serialize' as an hash key. This is not treated by module! 
  $q->enq({ some => [{complex => 'data'}],}, 
    );

  Hashes and Arrays must be passed as a reference! ALWAYS!

=item * alternative way(NOT RECOMMENDED): 
  
  $q->enq({value => 'Foo'});
  $q->enq({value => $Bar});
  $q->enq({value => \@MyArray});
  $q->enq({value => \%MyHash}); 
  $q->enq({value => { some => [{complex => 'data'}],} );  

=back

If you try to enqueue complex data, it will be serialized. Doesn't matter if serialize attribute or
parameter is set to false.

If you want to use alternative way, you must know the following valid parameters:

=over

=item value - A value that presupposes that you want to save

=item serialize - If you need the value to be serialized, you must set serialized to true(1). 

=back


Example2: $enq({value => $some_object_or_structure,
  serialize => 1, });


If this work, the method will return true. Otherwise, will return false.

You can change serialize parameters setting 'serializer' method too. 



=head2 deq()

Try to make a 'dequeue' operation on Queue. That means the first value
of queue will be removed from queue, and the first index pointer from queue will
be moved to the next index. If works, returns the 'dequeued' 
value, otherwise returns undef.

There is no parameters

Example:

 my $first_element_of_queue = $q->deq;



=head2 show()

Try to show the content of queue(the data). This is made finding the 'first' 
and 'last' pointers, extracting the sequential index, and interate the queue 
with this indexes, making a 'get' operation from Memcached. If the value
exists, it will be showed. If not, a exception will be thrown .

There is no parameters

Example:

say $q->show;


=head2 cleanup()

Dequeue everything! No parameters! Returns true, if it's all right! Otherwise, returns false/throws an exception



=head2 save( ArrayRef $parameters )

Internal method to save the queue metadata.


=head2 iterate(CODE $action, Array $action_params)

That method is a 'handler'. You can treat all values in another subroutine/static method, passing
two parameters:

=over

=item * action: this parameter MUST be a CODE reference. Example:

 #EX1: $q->iterate( 
 sub {   
  my ($index,$value,$params) = @_;
  #do something with this!!!
 }

 #EX2: $q->iterate( \&somesubroutine,$myparams) ;
 sub somesubroutine {
   my ($index,$value,$params) = @_;
   #do something cool!
 }

=item * action_params: This can be a custom parameters. All yours! 



=back 


So, by default, every index and values that are in your queue are passed together with your customized parameters.

If you pass everything right, your 'action' will be performed! Otherwise, an exception will be throwed.

=cut

=head1 AUTHOR

Andre Garcia Carneiro, C<< <bang at cpan.org> >>

=head1 BUGS

The queue lost reference to last element when there is more than one process accessing queue. I'm working on it.  

Please report any bugs or feature requests to C<bug-cache-memcached-queue at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cache-memcached-Queue>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 NOTES FOR THIS VERSION

=over

=item * 'beta' version was change to 'unstable', because multi-processing access is not working well yet.

=item * The auto-installer was removed after CPAN request.
 
=item * 'servers' attribute have ['localhost:11211'] as default value;

=item * 'serialize' attribute is DEPRECATED. Doesn't work anymore;

=item * The new method 'iterator' allows delegate to other subroutine/static method queue data;

=item * 'lock' feature is a internal feature that allows have a same queue with multiple processes working on it. (EXPERIMENTAL) 

=item * 'init' method was removed!

=back


=head1 TODO

=over

=item * performance optimization

=item * 'priority' support, maybe


=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Cache::Memcached::Queue


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cache-memcached-Queue>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cache-memcached-Queue>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cache-memcached-Queue>

=item * Search CPAN

L<http://search.cpan.org/dist/Cache-memcached-Queue/>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2013 2014 Andre Garcia Carneiro.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;  # End of Cache::Memcached::Queue

## Please see file perltidy.ERR
