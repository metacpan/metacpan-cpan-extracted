package Astro::Utils;

$Astro::Utils::VERSION   = '0.03';
$Astro::Utils::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Astro::Utils - Utility package for Astronomical Calculations.

=head1 VERSION

Version 0.03

=cut

use vars qw(@ISA @EXPORT);
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(calculate_equinox calculate_solstice);

use 5.006;
use strict; use warnings;
use Data::Dumper;
use DateTime;

my $PI   = 3.141592653589793;
my $TYPE = { 'MAR' => 0, 'JUN' => 1, 'SEP' => 2, 'DEC' => 3 };

=head1 DESCRIPTION

The entire algorithm is based on the  book "Astronomical Algorithms", 2nd Edition
by Jean Meeus,(C)1998, published by Willmann-Bell, Inc. I needed  this for one of
my package L<Calendar::Bahai>.

The calculated times are in Terrestrial Dynamical Time (TDT or TT), a replacement
for Ephemeris Times(ET).TDT is a uniform time used for astronomical calculations.

=head1 SYNOPSIS

    use strict; use warnings;
    use Astro::Utils;

    print "Mar'2015 Equinox  (UTC): ", calculate_equinox ('mar', 'utc', 2015),"\n";
    print "Mar'2015 Equinox  (TDT): ", calculate_equinox ('mar', 'tdt', 2015),"\n";

    print "Jun'2015 Solstice (UTC): ", calculate_solstice('jun', 'utc', 2015),"\n";
    print "Jun'2015 Solstice (TDT): ", calculate_solstice('jun', 'tdt', 2015),"\n";

    print "Sep'2015 Equinox  (UTC): ", calculate_equinox ('sep', 'utc', 2015),"\n";
    print "Sep'2015 Equinox  (TDT): ", calculate_equinox ('sep', 'tdt', 2015),"\n";

    print "Dec'2015 Solstice (UTC): ", calculate_solstice('dec', 'utc', 2015),"\n";
    print "Dec'2015 Solstice (TDT): ", calculate_solstice('dec', 'tdt', 2015),"\n";

=head1 METHODS

=head2 calculate_equinox($type, $timezone, $year)

The  param  C<$type>  can be either 'mar' or 'sep'. The param C<$timezone> can be
either 'UTC' or 'TDT'. And finally C<$year> can be anything between -1000 & 3000.
All parameters are required.

=cut

sub calculate_equinox {
    my ($type, $timezone, $year) = @_;

    die "ERROR: Year should be between -1000 and 3000.\n"
        unless (defined $year && ($year >= -1000) && ($year <= 3000));

    if ($timezone =~ /^utc$/i) {
        return _calc_utc_equinox($TYPE->{uc($type)}, $year);
    }
    elsif ($timezone =~ /^tdt$/i) {
        return _calc_tdt_equinox($TYPE->{uc($type)}, $year);
    }
    else {
        die "ERROR: Invalid timezone [$timezone] received.\n";
    }
}

=head2 calculate_solstice($type. $timezone, $year)

The  param  C<$type>  can be either 'jun' or 'dec'. The param C<$timezone> can be
either 'UTC' or 'TDT'. And finally C<$year> can be anything between -1000 & 3000.
All parameters are required.

=cut

sub calculate_solstice {
    my ($type, $timezone, $year) = @_;

    die "ERROR: Year should be between -1000 and 3000.\n"
        unless (defined $year && ($year >= -1000) && ($year <= 3000));

    if ($timezone =~ /^utc$/i) {
        return _calc_utc_solstice($TYPE->{uc($type)}, $year);
    }
    elsif ($timezone =~ /^tdt$/i) {
        return _calc_tdt_solstice($TYPE->{uc($type)}, $year);
    }
    else {
        die "ERROR: Invalid timezone [$timezone] received.\n";
    }
}

#
#
# PRIVATE METHODS

sub _calc_utc_equinox {
    my ($k, $year) = @_;

    die "ERROR: Invalid type for equinox.\n" unless (defined $k && ($k =~ /^[0|2]$/));
    my $jd = _calc_jd($k, $year);
    return _jd_to_utc($jd);
}

sub _calc_utc_solstice {
    my ($k, $year) = @_;

    die "ERROR: Invalid type for solstice.\n" unless (defined $k && ($k =~ /^[1|3]$/));
    my $jd = _calc_jd($k, $year);
    return _jd_to_utc($jd);
}

sub _calc_tdt_equinox {
    my ($k, $year) = @_;

    die "ERROR: Invalid type for equinox.\n" unless (defined $k && ($k =~ /^[0|2]$/));
    my $jd = _calc_jd($k, $year);
    return _jd_to_tdt($jd);
}

sub _calc_tdt_solstice {
    my ($k, $year) = @_;

    die "ERROR: Invalid type for solstice.\n" unless (defined $k && ($k =~ /^[1|3]$/));
    my $jd = _calc_jd($k, $year);
    return _jd_to_tdt($jd);
}

sub _calc_jd {
    my ($k, $year) = @_;

    # Astronmical Algorithms, Chapter 27.
    my $jde0 = _jde0($k, $year);
    my $t    = ($jde0 - 2451545.0) / 36525;
    my $w    = 35999.373 * $t - 2.47;
    my $dl   = 1 + 0.0334 * _cos($w) + 0.0007 * _cos(2 * $w);
    my $s    = _periodic_term_24($t);

    return ($jde0 + ( (0.00001 * $s) / $dl ));
}

sub _jd_to_utc {
    my ($jd) = @_;

    my ($yr, $mon, $day, $hr, $min, $sec) = _process($jd);

    my $date = DateTime->new(year => $yr, month => $mon, day => $day, hour => $hr, minute => $min, second => $sec);

    # Astronmical Algorithms, Chapter 10, page 79 (Table 10.A).
    my $first = 1620;
    my $last  = 2002;
    my @tbl   = (121,112,103,95,88,82,77,72,68,63,60,56,53,51,48,46,44,42,40,38,             # 1620
                 35,33,31,29,26,24,22,20,18,16,14,12,11,10,9,8,7,7,7,7,                      # 1660
                 7,7,8,8,9,9,9,9,9,10,10,10,10,10,10,10,10,11,11,11,                         # 1700
                 11,11,12,12,12,12,13,13,13,14,14,14,14,15,15,15,15,15,16,16,                # 1740
                 16,16,16,16,16,16,15,15,14,13,                                              # 1780
                 13.1,12.5,12.2,12.0,12.0,12.0,12.0,12.0,12.0,11.9,11.6,11.0,10.2,9.2,8.2,   # 1800
                 7.1,6.2,5.6,5.4,5.3,5.4,5.6,5.9,6.2,6.5,6.8,7.1,7.3,7.5,7.6,                # 1830
                 7.7,7.3,6.2,5.2,2.7,1.4,-1.2,-2.8,-3.8,-4.8,-5.5,-5.3,-5.6,-5.7,-5.9,       # 1860
                 -6.0,-6.3,-6.5,-6.2,-4.7,-2.8,-0.1,2.6,5.3,7.7,10.4,13.3,16.0,18.2,20.2,    # 1890
                 21.1,22.4,23.5,23.8,24.3,24.0,23.9,23.9,23.7,24.0,24.3,25.3,26.2,27.3,28.2, # 1920
                 29.1,30.0,30.7,31.4,32.2,33.1,34.0,35.0,36.5,38.3,40.2,42.2,44.5,46.5,48.5, # 1950
                 50.5,52.5,53.8,54.9,55.8,56.9,58.3,60.0,61.6,63.0,63.8,64.3                 # 1980, 2002 last entry
    );

    my $delta_t = 0;
    my $t = ($yr - 2000) / 100;

    if ($yr >= $first && $yr <= $last) {
        if ($yr % 2) {
            $delta_t = ($tbl[($yr - $first - 1) / 2] + $tbl[($yr - $first + 1) / 2] ) / 2;
        }
        else {
            $delta_t = $tbl[($yr - $first) / 2];
        }
    } elsif ($yr < 948) {
        $delta_t = 2177 + 497 * $t + (44.1 * _pow($t, 2));
    } elsif ($yr >= 948) {
        $delta_t =  102 + 102 * $t + (25.3 * _pow($t, 2));
        if ($yr >= 2000 && $yr <= 2100) {
            $delta_t += 0.37 * ($yr - 2100);
        }
    }

    $date->subtract(seconds => $delta_t);

    return sprintf("%04d-%02d-%02d %02d:%02d:%02d",
                   $date->year, $date->month, $date->day, $date->hour, $date->minute, $date->second);
}

sub _jd_to_tdt {
    my ($jd) = @_;

    my ($yr, $mon, $day, $hr, $min, $sec) = _process($jd);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $yr, $mon, $day, $hr, $min, $sec);
}

sub _process {
    my ($jd) = @_;

    # Astronmical Algorithms Chapter 7, page 63.
    my ($a, $alpha);
    my $z = int($jd + 0.5);
    my $f = ($jd + 0.5) - $z;

    if ($z < 2299161) {
        $a = $z;
    }
    else {
        $alpha = int(($z - 1867216.25) / 36524.25);
        $a = $z + 1 + $alpha - int($alpha / 4);
    }

    my $b   = $a + 1524;
    my $c   = int(($b - 122.1) / 365.25);
    my $d   = int(365.25 * $c);
    my $e   = int(($b -$d) / 30.6001);
    my $dt  = $b - $d - int(30.6001 * $e) + $f;
    my $mon = $e - (($e < 13.5)?(1):(13));
    my $yr  = $c - (($mon > 2.5)?(4716):(4715));
    my $day = int($dt);
    my $h   = 24 * ($dt - $day);
    my $hr  = int($h);
    my $m   = 60 * ($h - $hr);
    my $min = int($m);
    my $sec = int(60 * ($m - $min));

    return ($yr, $mon, $day, $hr, $min, $sec);
}

sub _periodic_term_24 {
    my ($t) = @_;

    # Astronmical Algorithms, Chapter 27, page 179 (Table 27.C).
    my @a = (485,203,199,182,156,136,77,74,70,58,52,
             50,45,44,29,18,17,16,14,12,12,12,9,8);
    my @b = (324.96,337.23,342.08,27.85,73.14,171.52,
             222.54,296.72,243.58,119.81,297.17,21.02,
             247.54,325.15,60.93,155.12,288.79,198.04,
             199.76,95.39,287.11,320.81,227.73,15.45);
    my @c = (1934.136,32964.467,20.186,445267.112,45036.886,
             22518.443,65928.934,3034.906,9037.513,
             33718.147,150.678,2281.226,29929.562,31555.956,
             4443.417,67555.328,4562.452,62894.029,
             31436.921,14577.848,31931.756,34777.259,
             1222.114,16859.074);

    my $s = 0;
    foreach my $i (0..23) {
        $s += ($a[$i] * _cos($b[$i] + ($c[$i] * $t)));
    }

    return $s;
}

sub _jde0 {
    my ($k, $year) = @_;

    # Julian Ephemeris Day Calculation.
    my ($jde0, $y);

    if ($year >= -1000 && $year <= 1000) {
        # Astronmical Algorithms, Chapter 27, page 178 (Table 27.A).
        $y = $year / 1000;

        if ($k == 0) {
            $jde0 = 1721139.29189 +
                    (365242.13740 * $y) +
                    (0.06134 * _pow($y, 2)) +
                    (0.00111 * _pow($y, 3)) -
                    (0.00071 * _pow($y, 4));
        }
        elsif ($k == 1) {
            $jde0 = 1721233.25401 +
                    (365241.72562 * $y) -
                    (0.05323 * _pow($y, 2)) +
                    (0.00907 * _pow($y, 3)) +
                    (0.00025 * _pow($y, 4));
        }
        elsif ($k == 2) {
            $jde0 = 1721325.70455 +
                    (365242.49558 * $y) -
                    (0.11677 * _pow($y, 2)) -
                    (0.00297 * _pow($y, 3)) +
                    (0.00074 * _pow($y, 4));
        }
        elsif ($k == 3) {
            $jde0 = 1721414.39987 +
                    (365242.88257 * $y) -
                    (0.00769 * _pow($y, 2)) -
                    (0.00933 * _pow($y, 3)) -
                    (0.00006 * _pow($y, 4));
        }
    }
    elsif ($year > 1000 && $year <= 3000) {
        # Astronmical Algorithms, Chapter 27, page 178 (Table 27.B).
        $y = ($year - 2000) / 1000;

        if ($k == 0) {
            $jde0 = 2451623.80984 +
                (365242.37404 * $y) +
                (0.05169 * _pow($y, 2)) -
                (0.00411 * _pow($y, 3)) -
                (0.00057 * _pow($y, 4));
        }
        elsif ($k == 1) {
            $jde0 = 2451716.56767 +
                (365241.62603 * $y) +
                (0.00325 * _pow($y, 2)) +
                (0.00888 * _pow($y, 3)) -
                (0.00030 * _pow($y, 4));
        }
        elsif ($k == 2) {
            $jde0 = 2451810.21715 +
                (365242.01767 * $y) -
                (0.11575 * _pow($y, 2)) +
                (0.00337 * _pow($y, 3)) +
                (0.00078 * _pow($y, 4));
        }
        elsif ($k == 3) {
            $jde0 = 2451900.05952 +
                (365242.74049 * $y) -
                (0.06223 * _pow($y, 2)) -
                (0.00823 * _pow($y, 3)) +
                (0.00032 * _pow($y, 4));
        }
    }

    return $jde0;
}

sub _pow {
    my ($n, $m) = @_;

    my $r = 1;
    foreach (1..$m) {
        $r *= $n;
    }

    return $r;
}

sub _cos {
    my ($degree) = @_;

    return cos(($degree * $PI)/180);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Astro-Utils>

=head1 BUGS

Please report any  bugs or feature requests to C<bug-astro-utils at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Astro-Utils>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Astro::Utils

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Astro-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Astro-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Astro-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Astro-Utils/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2017 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Astro::Utils
