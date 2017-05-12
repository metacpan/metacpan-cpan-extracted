use strict;
use warnings;
package Data::Bucketeer;
{
  $Data::Bucketeer::VERSION = '0.003';
}
# ABSTRACT: sort data into buckets based on threshholds

use Carp qw(croak);
use Scalar::Util ();
use List::Util qw(first);


sub new {
  my ($class, @rest) = @_;
  unshift @rest, '>' if ref $rest[0];

  my ($type, $buckets) = @rest;

  my @non_num = grep { ! Scalar::Util::looks_like_number($_) or /NaN/i }
                keys %$buckets;

  croak "non-numeric bucket boundaries: @non_num" if @non_num;

  my $guts = bless {
    buckets => $buckets,
    picker  => $class->__picker_for($type),
  };

  return bless $guts => $class;
}

my %operator = (
  '>' => sub {
    my ($self, $this) = @_;
    first { $this > $_ } sort { $b <=> $a } keys %{ $self->{buckets} };
  },
  '>=' => sub {
    my ($self, $this) = @_;
    first { $this >= $_ } sort { $b <=> $a } keys %{ $self->{buckets} };
  },

  '<=' => sub {
    my ($self, $this) = @_;
    first { $this <= $_ } sort { $a <=> $b } keys %{ $self->{buckets} };
  },
  '<' => sub {
    my ($self, $this) = @_;
    first { $this < $_ } sort { $a <=> $b } keys %{ $self->{buckets} };
  },
);

sub __picker_for {
  my ($self, $type) = @_;
  return($operator{ $type } || croak("unknown bucket operator: $type"));
}


sub result_for {
  my ($self, $input) = @_;

  my ($bound, $result) = $self->bound_and_result_for($input);

  return $result;
}


sub bound_and_result_for {
  my ($self, $input) = @_;

  my $bound = $self->{picker}->($self, $input);
  return (undef, undef) unless defined $bound;

  my $bucket = $self->{buckets}->{$bound};
  my $result = ref $bucket
            ? do { local $_ = $input; $bucket->($input) }
            : $bucket;

  return ($bound, $result);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Bucketeer - sort data into buckets based on threshholds

=head1 VERSION

version 0.003

=head1 OVERVIEW

Data::Bucketeer lets you easily map values in ranges to results.  It's for
doing table lookups where you're looking for the key in a range, not a list of
fixed values.

For example, you sell widgets with prices based on quantity:

  YOU ORDER    | YOU PAY, EACH
  -------------+---------------
    1 -  100   |  10 USD
  101 -  200   |   5 USD
  201 -  500   |   4 USD
  501 - 1000   |   3 USD
  1001+        |   2 USD

This can be easily turned into a bucketeer:

  use Data::Bucketeer;

  my $buck = Data::Bucketeer->new({
       0 => 10,
     100 => 5,
     200 => 4,
     500 => 3,
    1000 => 2,
  });

  my $cost = $buck->result_for( 701 ); # cost is 3

By default, the values I<exclusive minima>.  For example, above, you end up
with a result of C<3> by having an input C<strictly greater than> 500, and
C<less than or equal to> 500.  If you want to use a different operator, you can
specify it like this:

  my $buck = Data::Bucketeer->new( '>=', {
       1 => 10,
     101 => 5,
     201 => 4,
     501 => 3,
    1001 => 2,
  });

  my $cost = $buck->result_for( 701 ); # cost is 3

This distinction can be useful when dealing with non-integers.  The understood
operators are:

=over 4

=item *

>

=item *

>=

=item *

<=

=item *

<

=back

If the result value is a code reference, it will be invoked with C<$_> set to
the input.  This can be used for dynamically generating results, or to throw
exceptions.  Here is a contrived example of exception-throwing:

  my $greeting = Data::Bucketeer->new( '>=', {
    '-Inf' => sub { die "secs-into-day must be between 0 and 86399; got $_" },

         0 => "Good evening.",
    28_800 => "Good morning.",
    43_200 => "Good afternoon.",
    61_200 => "Good evening.",

    86_400 => sub { die "secs-into-day must be between 0 and 86399; got $_" },
  });

=head1 METHODS

=head2 result_for

  my $result = $buck->result_for( $input );

This returns the result for the given input, as described L<above|/OVERVIEW>.

=head2 bound_and_result_for

  my ($bound, $result) = $buck->bound_and_result_for( $input );

This returns two values:  the boundary key whose result was used, and the
result itself.

Using the item quantity price above, for example:

  my $buck = Data::Bucketeer->new({
       0 => 10,
     100 => 5,
     200 => 4,
     500 => 3,
    1000 => 2,
  });

  my ($bound, $cost) = $buck->bound_and_result_for( 701 );

  # $bound is 500
  # $cost  is 3

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
