package Color::Similarity;

=head1 NAME

Color::Similarity - common interface to different Color::Similarity::* modules

=head1 SYNOPSIS

  use Color::Similarity;

  my $package = ...; # for example Color::Similarity::HCL

  my $s = Color::Similarity->new( $package );

  my $d1 = $s->distance( [ $r1, $g1, $b1 ], [ $r2, $g2, $b2 ] );

=cut

use strict;

our $VERSION = '0.01';

=head1 METHODS

=head2 new

  my $s = Color::Similarity->new( $package );

Constructs a new C<Color::Similarity> object wrapping the given
C<$package>.  The module will not try to load the package, so the
caller must have done it already.

=cut

sub new {
    my( $class, $package ) = @_;

    bless $package->_vtable, $class;
}

=head2 distance_rgb

  my $d = $s->distance_rgb( [ $r1, $g1, $b1 ], [ $r2, $g2, $b2 ] );

Converts the RGB triplets to the appropriate representation (usually a
different colorspace) and computes their distance.

=cut

sub distance_rgb {
    my( $self, $t1, $t2 ) = @_;

    return &{$self->{distance_rgb}}( $t1, $t2 );
}

=head2 convert_rgb

  my $c = $s->convert_rgb( $r, $g, $b );

Converts the given RGB triplet to a representation suitable for
passing it to C<distance>.

=cut

sub convert_rgb {
    my( $self, $r, $g, $b ) = @_;

    return &{$self->{convert_rgb}}( $r, $g, $b );
}

=head2 distance

  my $d = $s->distance( $c1, $c2 );

Computes the distance between two colors already in an appropriate
representation (either using C<convert_rgb> or by alternate means).

=cut

sub distance {
    my( $self, $t1, $t2 ) = @_;

    return &{$self->{distance}}( $t1, $t2 );
}

=head1 SEE ALSO

L<Color::Similarity::Lab>, L<Color::Similarity::RGB>, L<Color::Similarity::HCL>

=head1 AUTHOR

Mattia Barbon, C<< <mbarbon@cpan.org> >>

=head1 COPYRIGHT

Copyright (C) 2007, Mattia Barbon

This program is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
