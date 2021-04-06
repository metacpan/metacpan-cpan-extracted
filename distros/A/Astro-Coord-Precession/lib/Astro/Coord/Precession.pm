package Astro::Coord::Precession;

use 5.006;
use strict;
use warnings;
use utf8;

use Math::Trig;

=encoding UTF-8

=head1 NAME

Astro::Coord::Precession - Precess coordinates between 2 epochs

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Exporter qw(import);

our @EXPORT_OK = qw(
    precess_rad
    precess
    read_coordinates
);

our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

=head1 SYNOPSIS

 use Astro::Coord::Precession qw/precess precess_rad read_coordinates/;

 # If you have coordinates in float RA hours and Dec degrees:
 my $precessed = precess([$RA, $dec], $epoch_from, $epoch_to);
    
 # If you have coordinates in rad:
 my $precessed_rad = precess([$RA_rad, $dec_rad], $epoch_from, $epoch_to);

 # If you have coordinates in strings with RA h,m,s and Dec deg etc:
 my $coord = read_coordinates(['01 33 50.904', '+30 39 35.79']);
 my $precessed = precess($coord, 2000, 2021.15);

=head1 DESCRIPTION

A very simple, pure Perl module to precess equatorial coordinates from one epoch
to another, based on the algorithm P. Herget used in the Publications of the
Cincinnati Observatory.

=head1 METHODS

=head2 precess

 my $precessed = precess($coord, $epoch_from, $epoch_to);

Returns an arrayref C<[$RA, $dec]> with equatorial coordinates (0 <= RA < 24 in
hours, -90 <= Dec <= 90 in degrees), precessed from C<$epoch_from> (e.g. 2000)
to C<$epoch_to>.

C<$coord> input is similarly arrayref with RA in hours, Dec in degrees.

=cut

sub precess {
    my ($coord, $epoch1, $epoch2) = @_;

    $coord->[0] *= pi() / 12;
    $coord->[1] *= pi() / 180;

    $coord = precess_rad($coord, $epoch1, $epoch2);

    $coord->[0] *= 12 / pi();
    $coord->[1] *= 180 / pi();

    return $coord;
}

=head2 precess_rad

 my $precessed_rad = precess($coord, $epoch_from, $epoch_to);

Returns an arrayref C<[$RA, $dec]> with equatorial coordinates in rad, precessed
from C<$epoch_from> (e.g. 2000) to C<$epoch_to>.

The L<precess> function converts from/to rad anyway, so use this if you can work
with rad directly.

=cut

sub precess_rad {
    my ($coord, $epoch1, $epoch2) = @_;

    my $ra1  = $coord->[0];
    my $dec1 = $coord->[1];
    my $csr  = 0.17453292519943e-01 / 3600;
    my $t    = 0.001 * ( $epoch2 - $epoch1 );
    my $st   = 0.001 * ( $epoch1 - 1900 );
    my $a    =
        $csr * $t *
        (23042.53 + $st * (139.75 + 0.06 * $st) +
            $t * (30.23 - 0.27 * $st + 18 * $t));
    my $b = $csr * $t * $t * (79.27 + 0.66 * $st + 0.32 * $t) + $a;
    my $c =
        $csr * $t *
        (20046.85 - $st * (85.33 + 0.37 * $st) +
            $t * (-42.67 - 0.37 * $st - 41.8 * $t));
    my $sina = sin($a);
    my $sinb = sin($b);
    my $sinc = sin($c);
    my $cosa = cos($a);
    my $cosb = cos($b);
    my $cosc = cos($c);
    my @r    = ([0, 0, 0], [0, 0, 0], [0, 0, 0]);
    $r[0][0] = $cosa * $cosb * $cosc - $sina * $sinb;
    $r[0][1] = -$cosa * $sinb - $sina * $cosb * $cosc;
    $r[0][2] = -$cosb * $sinc;
    $r[1][0] = $sina * $cosb + $cosa * $sinb * $cosc;
    $r[1][1] = $cosa * $cosb - $sina * $sinb * $cosc;
    $r[1][2] = -$sinb * $sinc;
    $r[2][0] = $cosa * $sinc;
    $r[2][1] = -$sina * $sinc;
    $r[2][2] = $cosc;

    $a = cos($dec1);
    my @x1 = ($a * cos($ra1), $a * sin($ra1), sin($dec1));
    my @x2 = (0, 0, 0);
    $x2[$_] = $r[$_][0] * $x1[0] + $r[$_][1] * $x1[1] + $r[$_][2] * $x1[2]
        for (0 .. 2);

    my $ra2 = atan2($x2[1], $x2[0]);
    $ra2 += 2 * pi() if $ra2 < 0;
    my $dec2 = asin($x2[2]);
    return [$ra2, $dec2];
}

=head1 UTILITY FUNCTIONS

=head2 read_coordinates

 my $coord = read_coordinates([$ra_string, $dec_string]);

Returns coordinates in an arrayref of RA, dec in decimal values to use with L<precess>.
It accepts commonly used strings for RA, dec in hours and degrees respectivelly:

=over 4
 
=item * C<$ra_string>

It will read a string with hours, minutes, secs like C<'2 30 00'> or C<'2h30m30s'>
or C<'02:30:30'> etc. Single/double quotes and single/double prime symbols are
accepted for denoting minute, second in place of a single space/tab which also works.
Will accept negative too with preceding -, even though this is unusual and also
no seconds part.

=item * C<$dec_string>

It will read a string with degrees, minutes, secs like C<'+54 30 00'> or C<'54°30m30s'>
etc. Single/double quotes and single/double prime symbols are accepted for denoting
minute, second in place of a single space/tab which also works. Will also accept
no arc seconds part.

=back

=cut

sub read_coordinates {
    my ($ra, $dec) = @{$_[0]};
    if (defined $ra && $ra =~ /([-]?)\s?([0-9.]+)[\sh:]+([0-9.]+)[\sm′':]+([0-9.]+)?/) {
        $ra = $2+$3/60;
        $ra += $4/3600 if $4;
        $ra *= -1 if length($1);
    }
    if (defined $dec && $dec =~ /([-]?)\s?([0-9.]+)[\sd°]+([0-9.]+)[\sm′']+([0-9.]+)?/) {
        $dec = $2+$3/60;
        $dec += $4/3600 if $4;
        $dec *= -1 if length($1)
    }
    return [$ra, $dec];
}

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-astro-coord-precession at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Astro-Coord-Precession>.
You could also raise issues or submit PRs to the github repo below.

=head1 GIT

L<https://github.com/dkechag/Astro-Coord-Precession>

=head1 ACKNOWLEDGEMENTS

Based on the precession function from the fortran program CONFND, made by FO @ CDS
(francois@simbad.u-strasbg.fr).

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2021 by Dimitrios Kechagias.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
