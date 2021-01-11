package Astro::Coord::ECI::VSOP87D::[% body %];

use 5.008;

use strict;
use warnings;

use base qw{ [% superclass %] };

our $VERSION = '0.001';

sub __model_definition {
    my ( undef, $key ) = @_;
    return [% model %]->{$key};
}

1;

__END__

=head1 NAME

Astro::Coord::ECI::VSOP87D::[% body %] - VSOP87D model of the position of [% body %]

=head1 SYNOPSIS

 use Astro::Coord::ECI::VSOP87D::[% body %];
 use Astro::Coord::ECI::Utils qw{ deg2rad };
 use POSIX qw{ strftime };
 use Time::Local qw{ localtime };
 
 my $station = Astro::Coord::ECI->new(
     name => 'White House',
 )->geodetic(
     deg2rad( 38.899 ),  # radians
     deg2rad( -77.038 ), # radians
     16.68/1000,         # Kilometers
 );
 my $venus = Astro::Coord::ECI::VSOP87D::[% body %]->new(
     station => $station,
 );
 my $today = timelocal( 0, 0, 0, ( localtime )[ 3 .. 5 ] );
 foreach my $item ( $venus->almanac( $today, $today + 86400 ) ) {
     local $\ = "\n";
     print strftime( '%d-%b-%Y %H:%M:%S', localtime $item->[0] ),
         $item->[3];
 }

=head1 DESCRIPTION

This Perl class computes the position of [% body %] using the VSOP87D
model. It is a subclass of
L<[% superclass %]|[% superclass %]>.

=head1 METHODS

This class supports no additional public methods.

=head2 ATTRIBUTES

This class has no additional attributes.

=head1 SEE ALSO

L<Astro::Coord::ECI|Astro::Coord::ECI>

L<Astro::Coord::ECI::VSOP87D|Astro::Coord::ECI::VSOP87D>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://github.com/trwyant/perl-Astro-Coord-ECI-VSOP87D/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) [% year %] by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set filetype=perl textwidth=72 :
