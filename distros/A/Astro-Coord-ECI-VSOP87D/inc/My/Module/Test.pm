package My::Module::Test;

use 5.008;

use strict;
use warnings;

use Astro::Coord::ECI;
use Astro::Coord::ECI::Utils qw{ AU deg2rad rad2deg };
use Carp;
use Exporter qw{ import };
use Test::More 0.88;	# Because of done_testing();

our $VERSION = '0.002';

our @EXPORT = qw{
    is_au_au
    is_km_au
    is_rad_deg
    strftime_h
    strftime_m
    washington_dc
};

{
    package Astro::Coord::ECI::VSOP87D;
    use constant DEBUG => $ENV{VSOP87D_DEBUG};
}

sub is_au_au ($$$$) {
    my ( $got, $want, $dp, $title ) = @_;
    my $tplt = "%.${dp}f";
    @_ = (
	sprintf( $tplt, $got ),
	sprintf( $tplt, $want ),
	$title,
    );
    goto &is;
}

sub is_km_au ($$$$) {
    splice @_, 0, 1, $_[0] / AU;
    goto &is_au_au;
}

sub is_rad_deg ($$$$) {
    my ( $got, $want, $dp, $title ) = @_;
    my $tplt = "%.${dp}f";
    @_ = (
	sprintf( $tplt, rad2deg( $got ) ),
	sprintf( $tplt, $want ),
	$title,
    );
    goto &is;
}

sub strftime_h {
    my ( $time ) = @_;
    return POSIX::strftime( '%Y-%m-%d %H', gmtime( $time + 1800 ) );
}

sub strftime_m {
    my ( $time ) = @_;
    return POSIX::strftime( '%Y-%m-%d %H:%M', gmtime( $time + 30 ) );
}

sub washington_dc {
    return Astro::Coord::ECI->new(
    )->geodetic(
	deg2rad( 38.89 ),
	deg2rad( -77.03 ),
	0,
    );
}

1;

__END__

=head1 NAME

My::Module::Test - Things useful when testing Astro::Coord::ECI::VSOP87D

=head1 SYNOPSIS

 use lib qw{ inc };
 
 use My::Module::Test;
 
 is_rad_deg $lambda, 98.27513, 4, 'Latitude to 4 decimal places';

=head1 DESCRIPTION

This Perl module contains subroutines that are useful in testing the
modules in C<Astro-Coord-ECI-VSOP87D>. It and all its contents are
private to that package, and may be changed or retracted without notice.
Documentation is for the benefit of the author.

Because of the way debugging is supported, this module must be loaded
before any of the C<Astro::Coord::ECI::VSOP87D> modules are loaded.

=head1 SUBROUTINES

This package exports the following package-private subroutines:

=head2 is_au_au

 is_au_au $Delta, 0.908_374_62, 6, 'Radius to 6 decimal places';

The arguments to this subroutine are:

=over

=item The computed value, in astronomical units

=item The desired value, in astronomical units

=item The number of decimal places to compare

=item The test title

=back

The first and second argument values are formatted to the number of
decimal places specified by the third argument, using C<sprintf
"%.${dp}f">. Then the altered first and second arguments, plus the
fourth argument, are passed to C<Test::More::is()> using a co-routine
call.

=head2 is_km_au

 is_km_au $Delta, 0.908_374_62, 6, 'Radius to 6 decimal places';

The arguments to this subroutine are:

=over

=item The computed value, in kilometers

=item The desired value, in astronomical units

=item The number of decimal places to compare

=item The test title

=back

The first argument is converted to astronomical units, and then both
values are formatted to the number of decimal places specified by the
third argument, using C<sprintf "%.${dp}f">. The altered first and
second arguments, plus the fourth argument, are passed to
C<Test::More::is()> using a co-routine call.

=head2 is_rad_deg

 is_rad_deg $lambda, 98.27513, 4, 'Latitude to 4 decimal places';

The arguments to this subroutine are:

=over

=item The computed value, in radians

=item The desired value, in degrees

=item The number of decimal places to compare

=item The test title

=back

The first argument is converted to degrees, and then both values are
formatted to the number of decimal places specified by the third
argument, using C<sprintf "%.${dp}f">. The altered first and second
arguments, plus the fourth argument, are passed to C<Test::More::is()>
using a co-routine call.

=head2 strftime_h

This subroutine takes as its argument a Perl time, formats it as a time
in UT, to the nearest hour. The format is C<'%Y-%m-%d %H'>.

=head2 strftime_m

This subroutine takes as its argument a Perl time, formats it as a time
in UT, to the nearest minute. The format is C<'%Y-%m-%d %H:%M'>.

=head2 washington_dc

This subroutine takes no arguments. It returns an
L<Astro::Coord::ECI|Astro::Coord::ECI> object representing the United
States Naval Observatory's position for Washington D.C.

=head1 MANIFEST CONSTANTS

This module provides the following manifest constants:

=head2 Astro::Coord::ECI::VSOP87D::DEBUG

This constant is set to the value of environment variable
C<VSOP87D_DEBUG>.

=head1 SEE ALSO

L<Astro::Coord::ECI::VSOP87D|Astro::Coord::ECI::VSOP87D>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
