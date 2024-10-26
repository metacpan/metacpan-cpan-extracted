package Cache::Memcached::PDeque;

use 5.006;
use strict;
use warnings;

use Cache::Memcached::Fast;
use Carp::Assert;
use Data::Dump;
use Moose;
use Moose::Util::TypeConstraints;
use Try::Tiny;

=head1 NAME

Cache::Memcached::PDeque - Implements a priority deque using memcached as storage

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

  use Cache::Memcached::PDeque;

  # Create a PDeque with a priorities 1 and 2
  my $dq = Cache::Memcached::PDeque->new( name => 'aName', max_prio => 2 );

  # Add and remove some elements
  $dq->push('a');    # ('a')
  $dq->unshift('b'); # ('b','a')
  $dq->push('c');    # ('b','a','c')

  $dq->pop();       # returns 'c'
  $dq->pop();       # returns 'a'
  $dq->shift();     # returns 'b'

  # Make use of priorities
  $dq->push_with_priority(1,'l1'); # ('l1')
  $dq->push_with_priority(1,'l2'); # ('l1','l2')
  $dq->push_with_priority(2,'h1'); # ('h1','l1','l2')
  $dq->push_with_priority(1,'l3'); # ('h1','l1','l2','l3')
  $dq->push_with_priority(2,'h2'); # ('h1','h2','l1','l2','l3')

  $dq->shift();     # returns 'h1'
  $dq->shift();     # returns 'h2'
  $dq->shift();     # returns 'l1'
  $dq->shift();     # returns 'l2'
  $dq->shift();     # returns 'l3'

  # Complex structures are supported
  my @list = ( 1, 'a', 2, 'b', 3, 'c' );
  $dq->push(\@list);   # Push reference to a list
  my $href = $dq->pop; # Get back reference to a list
  
=head1 DESCRIPTION

This is an implementation of a double-ended queue, with support for priorities.

A double-ended queue, abbreviated to deque, is an abstract data type that combines the functionality of a queue and a stack,
allowing elements to be added to, and removed from, both the front and the back.

In addition, this implementation adds support for associating a priority with an element, making it possible to serve
elements with a higher priority before elements with a lower priority.

The storage backend for this implementation is Memcached, an in-memory key-value store for small chunks of arbitrary data
(strings, objects). Cache::Memecached::Fast is used to access to Memcached.

=head1 METHODS

=cut

subtype 'Name',
  => as 'Str',
  => where { /^[a-zA-Z0-9]+$/ },
  => message { "$_ must match /[a-zA-Z0-9]+/" };

# Priority supported is [1..$max_prio]
our $max_prio = 10;

subtype 'Priority',
  => as 'Int',
  => where { 1 <= $_ && $_ <= $max_prio },
  => message { "$_ is not in range [$1-$max_prio]" };

# A prefix in memcached for everything we create
our $prefix = 'PDeque';  

# The initial value of head and tail. Could be 0 if we only ever
# push (rather than unshift). If we started with 0, we would not
# be able to unshift because memcached incr/decr works with
# positive ints. So use a big number here and hope we never (only)
# do push or unshift...
our $initial_head_tail = 2**31; 

has 'name'         => ( is => 'ro', isa => 'Name', required => 1 );
has 'max_prio'    =>  ( is => 'ro', isa => 'Priority', default => 1, writer => '_private_set_max_prio' );
has 'prioritizer'  => ( is => 'rw', default => undef );
has 'servers'      => ( is => 'rw', default => sub { return [ '127.0.0.1:11211' ] } );

has 'memcached'    => ( is => 'rw', isa => 'Cache::Memcached::Fast', init_arg => undef );

=head2 CONSTRUCTOR

  my $dq = Cache::Memcached::PDeque->new( 
                                name => 'aName',
                                max_prio => 1,
                                prioritizer => undef,
                                servers => [ '127.0.0.1:11211' ],
                            );

  Create new PDeque object.

=head3 name

Set the name of the dqueue; is a required argument.
This will be part of the prefix used in Memcached. Is should be unique.

=head3 max_prio

Sets the maximum priority for this dqueue. Must be a value in the range [1..10]. Defaults to 1.

=head3 prioritizer

A reference to a subroutine that must return a priority in the range [1..max_prio].
It is called for each element that is added by either push() or unshift().
The default is 'undef', which uses the lowest priority '1' for 'push' and the highest
priority 'max_prio' for unshift.

  my $dqr = Cache::Memcached::PDeque->new( name => 'aName', 
                                           max_prio => 2,
                                           prioritizer => \&remainder ); 

  sub remainder {
    my $element = shift;
    my $prio = $element % 2; # This is either 0 or 1
    return $prio+1;          # This is 1 or 2, a valid priority
  }

  $dqr->push(1); # ( 1 )
  $dqr->push(2); # ( 1 2 )
  $dqr->push(3); # ( 1 3 2 )
  $dqr->shift;   # returns 1
  $dqr->shift;   # returns 3
  $dqr->shift;   # returns 2

=head3 servers

A list of Memcached servers to connect to. Defaults to '127.0.0.1:11211'.

=cut

sub BUILD {
  my ( $self ) = @_;
  $self->memcached(Cache::Memcached::Fast->new({
    'servers' => $self->servers(),
    #'debug' => 1,
    #'compress_threshold' => 1000,
    'namespace' => "$prefix:" . $self->name . ':',
  }));

  $self->_lock(0);
  #$DB::single = 1;

  my $high = $self->memcached->get('max_prio');

  if ( defined $high ) {
    # No need to initialize, already exists
    $self->_private_set_max_prio($high);
  } else {
    # Initialize new memcached deque
    $self->memcached->add_multi(['size', 0], ['max_prio', $self->max_prio]);

    foreach my $i ( 1 .. $self->max_prio ) {
      # For each priority, set size, head and tail
      $self->memcached->add_multi([$i . ':size', 0], [$i . ':head', $initial_head_tail], [$i . ':tail', $initial_head_tail]);
    }
  }

  $self->_unlock(0);

  return $self;
}

=head2 METHODS

The following public methods are available.

Please note that any methods starting with an underscore '_' are considered private, are undocumented, and are
subject to change without notice. Do not use private methods.

=head3 size

  my $size = $dq->size;

  Returns the number of elements in $dq.

=cut

sub size {
  my ( $self ) = @_;
  return int($self->memcached->get('size'));
}

=head3 push_with_priority

  $dq->push_with_priority($priority, $element);

  Adds $element after all elements with a higher or equal priority, and before all elements with a lower priority.

=cut

# Add element at back
sub push_with_priority {
   my ( $self, $priority, $data ) = @_;

  assert($priority >= 1 && $priority <= $self->max_prio) if DEBUG;

  try {
    $self->_lock($priority);

    my $index = $self->memcached->incr($priority . ':tail');
    $self->memcached->add($priority . ':' . $index, $data, 0);
    $self->memcached->incr_multi([$priority . ':size'],['size']);

    $self->_unlock($priority);
    return 1;

  } catch {
    $self->_unlock($priority);
    return 0;
  }
}

=head3 push

  $dq->push($element);

  Adds $element after all elements.

=cut

sub push {
  my ( $self, $data ) = @_;
  my $prio = defined $self->prioritizer ? $self->prioritizer->($data) : 1;
  return $self->push_with_priority($prio, $data);
}

=head3 unshift_with_priority

  $dq->unshift_with_priority($priority, $element);

  Inserts $element after all elements with a higher priority, and before all elements with a lower or equal priority.

=cut

# Add element at front
sub unshift_with_priority {
   my ( $self, $priority, $data ) = @_;

  assert($priority >= 1 && $priority <= $self->max_prio) if DEBUG;

  try {
    $self->_lock( $priority );

    my $index = $self->memcached->decr($priority . ':head');
    $self->memcached->add($priority . ':' . ($index+1), $data, 0);
    $self->memcached->incr_multi([$priority . ':size'],['size']);

    $self->_unlock($priority);

    return 1;
  } catch {
    $self->_unlock($priority);
    return 0;
  }
}

=head3 unshift

  $dq->unshift($element);

  Insert $element before all elements.

=cut

sub unshift {
  my ( $self, $data ) = @_;
  my $prio = defined $self->prioritizer ? $self->prioritizer->($data) : $self->max_prio;
  return $self->unshift_with_priority($prio, $data);
}

=head3 pop_with_priority

  my $element = $dq->pop_with_priority($priority);

  Returns the last element with the given priority.

=cut

# Remove last element (FILO)
sub pop_with_priority {
  my ( $self, $priority ) = @_;

  assert($priority >= 1 && $priority <= $self->max_prio) if DEBUG;

  try {
    $self->_lock($priority);

    my $first = $self->memcached->get($priority . ':head');
    my $index = $self->memcached->get($priority . ':tail');

    my $result = undef;

    if ( $index > $first ) {
      $result = $self->memcached->get($priority . ':' . $index);
      $self->memcached->delete($priority . ':' . $index);
      $self->memcached->decr('size');

      if ( 0 == $self->memcached->decr($priority . ':size')) {
        # Empty, reset head and tail
        $self->memcached->set_multi([$priority . ':head', $initial_head_tail],[$priority . ':tail', $initial_head_tail]);
      } else {
        # Not empty, simply update new value of tail
        $self->memcached->set($priority . ':tail', $index-1);
      }
    }

    $self->_unlock($priority);

    return $result;

  } catch {
    $self->_unlock($priority);
    return undef;
  }
}

=head3 pop

  my $element = $dq->pop;

  Returns the last element.

=cut

sub pop {
  my ( $self ) = @_;

  for ( my $prio=1; $prio<=$self->max_prio; $prio++ ) {
    my $result = $self->pop_with_priority($prio);
    return $result if defined $result;
  }
  return undef;
}

=head3 shift_with_priority

  my $element = $dq->shift_with_priority($priority);

  Returns the first element with the given priority.

=cut

# Remove first element (FIFO)
sub shift_with_priority {
  my ( $self, $priority ) = @_;

  assert($priority >= 1 && $priority <= $self->max_prio) if DEBUG;

  try {
    $self->_lock($priority);

    my $index = $self->memcached->get($priority . ':head');
    my $last = $self->memcached->get($priority . ':tail');

    my $result = undef;

    if ( $index++ < $last ) {
      $result = $self->memcached->get($priority . ':' . $index);
      $self->memcached->delete($priority . ':' . $index);
      $self->memcached->decr('size');

      if ( 0 == $self->memcached->decr($priority . ':size')) {
        # Empty, reset head and tail
        $self->memcached->set_multi([$priority . ':head', $initial_head_tail],[$priority . ':tail', $initial_head_tail]);
      } else {
        # Not empty, simply update new value of tail
        $self->memcached->set($priority . ':head', $index);
      }
    }

    $self->_unlock($priority);

    return $result;

  } catch {
    $self->_unlock($priority);
    return undef;
  }
}

=head3 shift

  my $element = $dq->shift;

  Returns the first element.

=cut

sub shift {
  my ( $self ) = @_;

  for ( my $prio=$self->max_prio; $prio>=1; $prio-- ) {
    my $result = $self->shift_with_priority($prio);
    return $result if defined $result;
  }
  return undef;
}

=head3 foreach

  sub do_something {
    my $el = shift;
    print "square of $el is " . $el ** 2 . "\n";
  }

  $dq->foreach(\&do_something);

  Executes a subroutine on every element.

  (!) Do not attempt to modify $dq from within the do_something() subroutine. This will cause a deadlock.

=cut

sub foreach {
  my ( $self, $func ) = @_;

  $self->_lock(0, timeout => 0);
  foreach my $prio ( $self->max_prio .. 1 ) {
    $self->_lock($prio, timeout => 0);
    my $href = $self->memcached->get_multi(($prio . ':head',$prio . ':tail'));
    my $head = $href->{$prio . ':head'};
    my $tail = $href->{$prio . ':tail'};
    while ( ++$head <= $tail ) {
      my $el = $self->memcached->get($prio . ':' . $head);
      $func->($el);
    }
    $self->_unlock($prio);
  }
  $self->_unlock(0);

}

sub _dump {
  my ( $self ) = @_;
  my @result;

  for ( my $prio=$self->max_prio; $prio>=1; $prio-- ) {

    $self->_lock($prio, timeout => 60);
    #$DB::single = 1;

    my $href  = $self->memcached->get_multi(($prio . ':head',$prio . ':tail'));
    my $first = $self->memcached->get($prio . ':head');
    my $last  = $self->memcached->get($prio . ':tail');

    foreach my $i ( $first+1 .. $last ) {
      CORE::push @result, $self->memcached->get($prio . ':' . $i);
    }

    $self->_unlock($prio);
  }

  return @result;
}

sub _check {
  my ( $self ) = @_;
  my $total_size = 0;
  foreach my $i ( 1 .. $self->max_prio ) {
    my $size = $self->memcached->get($i . ':size'); $total_size += $size;
    my $head = $self->memcached->get($i . ':head');
    my $tail = $self->memcached->get($i . ':tail');
    assert ( $size == $tail-$head )  if DEBUG;
  }
  assert ( $total_size == $self->memcached->get('size') ) if DEBUG;
  return 1;
}

# This is dangerous! It deletes *everything* stored in memcached.
sub _flush {
  my ( $self ) = @_;
  $self->memcached->flush_all;
}

sub _lock {
  my $self = CORE::shift;
  my $priority = CORE::shift;
  my ( %arg ) = (
    # The timeout below is supposed to set a timeout after which a lock is
    # automatically removed. Sounds great, and 1 second is an enternity, right?
    # WRONG! When set to 1, some of the test scripts sometimes fail due to a lock
    # being deleted by memcached. Which is very strange as a 1 second timeout for
    # just 1 single lock is a lot for a script that on my system requires less
    # than 300 msec to do everything... Conclusion: don't set this to 1!
    # 0, on the other hand, should be ok, as it means 'no timeout'.
    'timeout' => 2,
    @_
  );

  confess("Timeout must not be '1'") if $arg{'timeout'} == 1;

  while (1) {
    my $have_lock = $self->memcached->add("$priority:lock", $$, $arg{'timeout'});
    last if $have_lock;
    sleep(.1);
  }

  affirm {
    my $locked_by = $self->memcached->get("$priority:lock");
    $$ == $locked_by;
  };
}

sub _unlock {
  my ( $self, $priority ) = @_;

  affirm {
    my $locked_by = $self->memcached->get("$priority:lock");
    $$ == $locked_by;
  };

  $self->memcached->delete("$priority:lock");
}

no Moose;
#__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Peter Haijen, C<< <peterhaijen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cache-memcached-pdeque at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cache-Memcached-PDeque>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cache::Memcached::PDeque


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Cache-Memcached-PDeque>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Cache-Memcached-PDeque>

=item * Search CPAN

L<https://metacpan.org/release/Cache-Memcached-PDeque>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Peter Haijen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Cache::Memcached::PDeque
