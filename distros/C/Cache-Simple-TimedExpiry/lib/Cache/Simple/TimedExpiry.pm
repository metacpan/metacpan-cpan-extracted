package Cache::Simple::TimedExpiry;
use warnings;
use strict;

use vars qw/$VERSION/;

$VERSION = '0.27';

=head1 NAME

Cache::Simple::TimedExpiry

=head2 EXAMPLE 

 package main; 

 use strict; 
 use warnings;
 $,=' '; $|++;

 use Cache::Simple::TimedExpiry;
 my $h =  Cache::Simple::TimedExpiry->new;

 $h->set( DieQuick => "No duration!", 0); 
 print $h->elements;
 do { $h->set($_,"Value of $_", 1); sleep 2;} 
    for qw(Have a nice day you little monkey); 


 print $h->elements; $h->dump; sleep 4; print $h->elements; $h->dump;

 print time;


=cut


# 0 - expiration delay
# 1 - hash
# 2 - expiration queue
# 3 - last expiration

=head2 new

Set up a new cache object

=cut


sub new {
  bless [2,{},[],0], "Cache::Simple::TimedExpiry";
}


=head2 expire_after SECONDS

Set the cache's expiry policy to expire entries after SECONDS seconds. Setting this changes the expiry policy for pre-existing cache entries and for new ones.


=cut

sub expire_after {
    my $self = shift;
    $self->[0] = shift if (@_);
    return ($self->[0]);

}


=head2 has_key KEY

Return true if the cache has an entry with the key KEY

=cut

sub has_key ($$) { # exists
  my ($self, $key) = @_;
  
  my $time = time;
  $self->expire($time) if ($time > $self->[3]);
  return 1 if defined $key && exists $self->[1]->{$key};
  return 0;
}

=head2 fetch KEY

Return the cache entry with key KEY.
Returns undef if there is no such entry

(Can also be called as L<get>)

=cut

*get = \&fetch;

sub fetch ($$) {
  my ($self,$key) = @_;

  # Only expire 
    unless ( $self->has_key($key)) {
          return undef;
     }

  return $self->[1]->{$key};

}

=head2 store KEY VALUE

Store VALUE in the cache with accessor KEY.  Expire it from the cache 
at or after EXPIRYTIME.

(Can also be called as L<set>)

=cut

*set = \&store;

sub store ($$$) {
  my ($self,$key,$value) = @_;
  my $time = time;
  # Only expire 
  $self->expire($time) if ($time > $self->[3]);

  return undef unless defined ($key);
  $self->[1]->{$key} = $value;

    push @{$self->[2]}, [ time, $key ];
}

sub expire ($$) {
  my $self = shift;
  my $time = shift;
    
  $self->[3] = $time;

  my $oldest_nonexpired_entry = ($time - $self->[0]);
 

  return unless defined $self->[2]->[0]; # do we have an element in the array?


  return unless $self->[2]->[0]->[0] < $oldest_nonexpired_entry; # is it expired?

  while ( @{$self->[2]} && $self->[2]->[0]->[0] <$oldest_nonexpired_entry ) {
    my $key =  $self->[2]->[0]->[1];
    delete $self->[1]->{ $key };
    shift @{$self->[2]};
  }

}

sub elements ($) { # keys
  my $self = shift;
  my $time = time;
  # Only expire 
  $self->expire($time) if ($time > $self->[3]);

  return keys %{$self->[1]};

}

sub dump ($) {
  require Data::Dumper;
  print Data::Dumper::Dumper($_[0]);
}



=head1 AUTHOR

Jesse Vincent <jesse@bestpractical.com>
Some of the heavy lifting was designed by Robert Spier <rspier@pobox.com>

Copyright 2004 Jesse Vincent <jesse@bestpractical.com>

=cut

1;
