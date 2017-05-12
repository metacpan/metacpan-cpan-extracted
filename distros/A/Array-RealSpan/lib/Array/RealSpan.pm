package Array::RealSpan;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Map real number ranges to labels or objects

our $VERSION = '0.0101';

use strict;
use warnings;
use Carp qw(croak);

use Moo;


has _ranges => (
    is      => 'rw',
    default => sub { [] },
);


sub set_range {
    my ( $self, $start, $end, $label ) = @_;

    croak('set_range() should be called with 3 values.')
        unless defined $start && defined $end && defined $label;
    croak("set_range() called with bad indices: $start, $end")
        if $end <= $start;

    push @{ $self->_ranges }, [ $start, $end, $label ];
}


sub get_range {
    my ( $self, $label ) = @_;
    my $get_range;
    for my $range ( @{ $self->_ranges } ) {
        if ( $label eq $range->[2] ) {
            $get_range = [ $range->[0], $range->[1] ];
            last;
        }
    }
    return $get_range;
}


sub lookup {
    my ( $self, $number ) = @_;
    my $lookup;
    for my $range ( @{ $self->_ranges } ) {
        if ( $number >= $range->[0] && $number < $range->[1] ) {
            $lookup = $range->[2];
            last;
        }
    }
    return $lookup;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::RealSpan - Map real number ranges to labels or objects

=head1 VERSION

version 0.0101

=head1 SYNOPSIS

  use Array::RealSpan;
  my $epoch = Array::RealSpan->new;
  $epoch->set_range(  0,     0.01, 'Holocene' );
  $epoch->set_range(  0.01,  1.81, 'Pliestocene' );
  $epoch->set_range(  1.81,  5.32, 'Pliocene' );
  $epoch->set_range(  5.32, 23.8,  'Miocene' );
  $epoch->set_range( 23.8,  33.7,  'Oligocene' );
  $epoch->set_range( 33.7,  55,    'Eocene' );
  $epoch->set_range( 55,    65,    'Paleocene' );
  my $name = $epoch->lookup(3.14);
  my $range = $epoch->get_range('Holocene');

=head1 DESCRIPTION

An C<Array::RealSpan> object maps real number ranges to associated labels or
objects.

=head1 NAME

Array::RealSpan - Map real number ranges to labels or objects

=head1 METHODS

=head2 new

  $span = Array::RealSpan->new;

Create a new C<Array::RealSpan> object.

=head2 set_range

  $span->set_range( $start, $end, $label );

Add a range, from start to end, for a given label or object.

=head2 get_range

  $range = $span->get_range($label);

Return the range for the given label or object.

=head2 lookup

  $label = $span->lookup($number);

Look up the label (or object) for the range containing the given number.

This compares each range by considering the number less than or equal to the
start and less than the end.

=head1 SEE ALSO

See L<Array::IntSpan> for a more featured implementation (but for integer ranges
only).

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
