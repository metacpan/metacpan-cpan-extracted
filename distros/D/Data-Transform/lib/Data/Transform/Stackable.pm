# vim: ts=3 sw=3 expandtab
package Data::Transform::Stackable;
use strict;

use Data::Transform;
use Scalar::Util qw(blessed);

use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = qw(Data::Transform);

use Carp qw(croak);

sub FILTERS () { 0 }

=pod

=head1 NAME

Data::Transform::Stackable - combine multiple Data::Transform objects

=head1 SYNOPSIS

=head1 DESCRIPTION

Data::Transform::Stackable combines multiple filters together in such a
way that they appear to be a single filter.  All the usual L<Data::Transform>
methods work, but data is secretly passed through the stacked filters
before it is returned.

Data added by get_one_start() will flow through the filter array in
increasing index order.  Filter #0 will have first crack at it,
followed by filter #1 and so.  The get_one() call will return an item
after it has passed through the last filter.

put() passes data through the filters in descending index order.  Data
will go through the filter with the highest index first, and put()
will return the results after data has passed through filter #0.

=head1 PUBLIC FILTER METHODS

Data::Transform::Stackable implements the L<Data::Transform> API. Only
differences and additions are documented here.

=cut

=head2 new

By default, new() creates an empty filter stack that behaves like
Data::Transform::Stream.  It may be given optional parameters to
initialize the stack with an array of filters.

  my $sudo_lines = Data::Transform::Stackable->new(
    Filters => [
      Data::Transform::Line->new(),
      Data::Transform::Grep->new(
        Put => sub { 1 }, # put all items
        Get => sub { shift() =~ /sudo\[\d+\]/i },
      ),
    ]
  );

=cut

sub new {
  my $type = shift;
  croak "$type must be given an even number of parameters" if @_ & 1;
  my %params = @_;

  $params{Filters} = [ ] unless defined $params{Filters};
  # Sanity check the filters
  if ( ref $params{Filters} eq 'ARRAY') {

    my $self = bless [
      $params{Filters}, # FILTERS
    ], $type;

    return $self;
  } else {
    croak "Filters is not an ARRAY reference!";
  }
}

sub clone {
  my $self = shift;

  my $clone = [
    [ ],    # FILTERS
  ];
  foreach my $filter (@{$self->[FILTERS]}) {
    push (@{$clone->[FILTERS]}, $filter->clone());
  }

  return bless $clone, ref $self;
}

sub get_pending {
  my ($self) = @_;
  my $data;
  for (@{$self->[FILTERS]}) {
    $_->put($data) if $data && @{$data};
    $data = $_->get_pending;
  }
  return $data || [];
}

sub get_one_start {
  my ($self, $data) = @_;
  $self->[FILTERS]->[0]->get_one_start($data);
}

# RCC 2005-06-28: get_one() needs to strobe through all the filters
# regardless whether there's data to input to each.  This is because a
# later filter in the chain may produce multiple things from one piece
# of input.  If we stop even though there's no subsequent input, we
# may lose something.
#
# Keep looping through the filters we manage until get_one() returns a
# record, or until none of the filters exchange data.

sub get_one {
  my ($self) = @_;

  my $return = [ ];

  while (!@$return) {
    my $exchanged = 0;

    foreach my $filter (@{$self->[FILTERS]}) {

      # If we have something to input to the next filter, do that.
      if (@$return) {
        $filter->get_one_start($return);
        $exchanged++;
      }

      # Get what we can from the current filter.
      $return = $filter->get_one();
      last if ( blessed $return->[0]
                and     $return->[0]->isa('Data::Transform::Meta::SENDBACK'));
    }

    last unless $exchanged;
  }

  return $return;
}

# get() is inherited from Data::Transform.

sub put {
  my ($self, $data) = @_;
  foreach my $filter (reverse @{$self->[FILTERS]}) {
    $data = $filter->put($data);
    last unless @$data;
  }
  $data;
}

=head2 filter_types

filter_types() returns a list of class names for each filter in the
stack, in the stack's native order.

=cut

sub filter_types {
   map { ref($_) } @{$_[0]->[FILTERS]};
}

=head2 filters

filters() returns a list of the filters inside the Stackable filter,
in the stack's native order.

=cut

sub filters {
  @{$_[0]->[FILTERS]};
}

=head2 shift

Behaves like Perl's built-in shift() for the filter stack.  The 0th
filter is removed from the stack and returned.  Any data remaining in
the filter's input buffer is passed to the new head of the stack, or
it is lost if the stack becomes empty.  An application may also call
L<Data::Transform/get_pending> on the returned filter to examine the
filter's input buffer.

  my $first_filter = $stackable->shift();
  my $first_buffer = $first_filter->get_pending();

=cut

sub shift {
  my ($self) = @_;
  my $filter = shift @{$self->[FILTERS]};
  my $pending = $filter->get_pending;
  $self->[FILTERS]->[0]->put( $pending ) if $pending;
  $filter;
}

=head2 unshift FILTER[, FILTER]

unshift() adds one or more new FILTERs to the beginning of the stack.
The newly unshifted FILTERs will process input first, and they will
handle output last.

=cut

sub unshift {
  my ($self, @filters) = @_;

  # Sanity check
  foreach my $elem ( @filters ) {
    if ( ! defined $elem or ! UNIVERSAL::isa( $elem, 'Data::Transform' ) ) {
      croak "Filter element is not a Data::Transform instance!";
    }
  }

  unshift(@{$self->[FILTERS]}, @filters);
}

=head2 push FILTER[, FILTER]

push() adds one or more new FILTERs to the end of the stack.  The
newly pushed FILTERs will process input last, and they will handle
output first.

  # Reverse data read through the stack.
  # rot13 encode data sent through the stack.
  $stackable->push(
    Data::Transform::Map->(
      Get => sub { return scalar reverse shift() },
      Put => sub { local $_ = shift(); tr[a-zA-Z][n-za-mN-ZA-M]; $_ },
    )
  );

=cut

sub push {
  my ($self, @filters) = @_;

  # Sanity check
  foreach my $elem ( @filters ) {
    if ( ! defined $elem or ! UNIVERSAL::isa( $elem, 'Data::Transform' ) ) {
      croak "Filter element is not a Data::Transform instance!";
    }
  }

  push(@{$self->[FILTERS]}, @filters);
}

=head2 pop

Behaves like Perl's built-in pop() for the filter stack.  The
highest-indexed filter is removed from the stack and returned.  Any
data remaining in the filter's input buffer is lost, but an
application may always call L<Data::Transform/get_pending> on the returned
filter.

  my $last_filter = $stackable->pop();
  my $last_buffer = $last_filter->get_pending();

=cut

sub pop {
  my ($self) = @_;
  my $filter = pop @{$self->[FILTERS]};
  my $pending = $filter->get_pending;
  $self->[FILTERS]->[-1]->put( $pending ) if $pending;
  $filter;
}

1;

__END__

=head1 SEE ALSO

L<Data::Transform> for more information about filters in general.

=head1 AUTHORS & COPYRIGHTS

The Stackable filter was contributed by Dieter Pearcey.  Documentation
provided by Rocco Caputo.

=cut

