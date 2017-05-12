package Calendar::Any::Util::Solar;
{
  $Calendar::Any::Util::Solar::VERSION = '0.5';
}
use Calendar::Any::Gregorian;
use Math::Trig;
our $timezone = _current_timezone();

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
timezone next_longitude_date longitude
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

sub timezone {
    my $longitude = shift;
    $longitude / 180 * 12 * 60;
}

my @data = (
    [403406, 4.721964, 1.621043],
    [195207, 5.937458, 62830.348067],
    [119433, 1.115589, 62830.821524],
    [112392, 5.781616, 62829.634302],
    [3891, 5.5474, 125660.5691],
    [2819, 1.5120, 125660.984],
    [1721, 4.1897, 62832.4766],
    [0, 1.163, 0.813],
    [660, 5.415, 125659.31],
    [350, 4.315, 57533.85],
    [334, 4.553, -33.931],
    [314, 5.198, 777137.715],
    [268, 5.989, 78604.191],
    [242, 2.911, 5.412],
    [234, 1.423, 39302.098],
    [158, 0.061, -34.861],
    [132, 2.317, 115067.698],
    [129, 3.193, 15774.337],
    [114, 2.828, 5296.670],
    [99, 0.52, 58849.27],
    [93, 4.65, 5296.11],
    [86, 4.35, -3980.70],
    [78, 2.75, 52237.69],
    [72, 4.50, 55076.47],
    [68, 3.23, 261.08],
    [64, 1.22, 15773.85],
    [46, 0.14, 188491.03],
    [38, 3.44, -7756.55],
    [37, 4.37, 264.89],
    [32, 1.14, 117906.27],
    [29, 2.84, 55075.75],
    [28, 5.96, -7961.39],
    [27, 5.09, 188489.81],
    [27, 1.72, 2132.19],
    [25, 2.56, 109771.03],
    [24, 1.92, 54868.56],
    [21, 0.09, 25443.93],
    [21, 5.98, -55731.43],
    [20, 4.03, 60697.74],
    [18, 4.47, 2132.79],
    [17, 0.79, 109771.63],
    [14, 4.24, -7752.82],
    [13, 2.01, 188491.91],
    [13, 2.65, 207.81],
    [13, 4.98, 29424.63],
    [12, 0.93, -7.99],
    [10, 2.21, 46941.14],
    [10, 3.59, -68.29],
    [10, 1.50, 21463.25],
    [10, 2.55, 157208.40]
);

#==========================================================
# Input  : Calendar object or absolute date, the degrees L, timezone
# Output : The next *absolute date* that sun's longitude
#          is a multiple of L degrees at that timezone
# Desc   : timezone default is $timezone
#==========================================================
sub next_longitude_date {
    my ($d, $l, $tz) = @_;
    if ( ref $d ) {
        $d = $d->absolute_date;
    }
    my $long;
    my $start = $d;
    my $start_long = longitude($d, $tz);
    my $next = (int($start_long/$l) + 1) * $l % 360;
    my $end = $d + $l/360*400;
    my $end_long = longitude($end);
    while ( $end-$start > 0.00001 ) {
        $d = ($start + $end)/2;
        $long = longitude($d);
        if ( (($next != 0) && ($long < $next))
                 || (($next==0) && ($l < $long)) ) {
            $start = $d;
            $start_long = $long;
        } else {
            $end = $d;
            $end_long = $long;
        }
    }
    return ($start+$end)/2;
}

#==========================================================
# Input  : Calendar object or absolute date, timezone
# Output : The sun's longitude of the date at that timezone
# Desc   : To simplified convertion, use absolute date instead
#          of astronomical date
#==========================================================
sub longitude {
    my $date = shift;
    my $tz = shift;
    defined($tz) || ($tz = $timezone);
    # TODO: daylight time offset
    $date = Calendar::Any::Gregorian->new((ref $date ? $date->absolute_date : $date) - $tz/60/24);
    $date = $date->astro_date + _ephemeris_correction($date->year);
    my $U = ($date - 2451545)/3652500;
    my $longitude = 0;
    foreach ( @data ) {
        $longitude += $_->[0] * sin($_->[1]+$U*$_->[2]);
    }
    $longitude = 4.9353929 + 62833.1961680 * $U + 0.0000001 * $longitude;
    my $aberration = 0.0000001 *(17 * cos(3.10 + 62830.14 *$U) - 973);
    my $nutation = -0.0000001* (834 * sin(2.19+$U*(0.36*$U - 3375.70)) + 64 * sin(3.51+ $U*(125666.39 + 0.10*$U)));
    return _mod(rad2deg($longitude + $aberration + $nutation), 360);
}

sub _mod {
    my ($num, $base) = @_;
    $num = $num - int($num/$base)*$base;
    return $num*$base < 0 ? $num+$base : $num;
}

sub _ephemeris_correction {
    my $year = shift;
    if ( $year > 1988 && $year < 2020 ) {
        ($year-2000+67)/60/60/24;
    } elsif ( $year>1900 && $year < 1988 ) {
        my $theta = (Calendar::Any::Gregorian->new(7, 1, $year)->astro_date -
                         Calendar::Any::Gregorian->new(1, 1, 1900)->astro_date)/36525;
        my $theta2 = $theta * $theta;
        my $theta3 = $theta2 * $theta;
        my $theta4 = $theta2 * $theta2;
        return -0.00002 + 0.000297 * $theta + 0.025184 * $theta2 - 0.181133 * $theta3 + 0.553040 * $theta4
            -0.861938 * $theta2 * $theta3 + 0.677066 * $theta3 * $theta3
                - 0.212591 * $theta3 * $theta4;
    }
    elsif ( $year>1800 && $year<1900 ) {
        my $theta = (Calendar::Any::Gregorian->new(7, 1, $year)->astro_date -
                         Calendar::Any::Gregorian->new(1, 1, 1900)->astro_date)/36525;
        my $theta2 = $theta * $theta;
        my $theta3 = $theta2 * $theta;
        my $theta4 = $theta2 * $theta2;
        my $theta5 = $theta3 * $theta2;
        return -0.000009 +  0.003844*$theta + 0.083563*$theta2 + 0.865736*$theta3
            + 4.867575*$theta4 + 15.845535*$theta5 + 31.332267*$theta3*$theta3
                + 38.291999*$theta4*$theta3 + 28.316289*$theta4*$theta4
                    + 11.636204*$theta4*$theta5 + 2.043794*$theta5*$theta5;
    }
    elsif ( $year>1620 && $year<1800 ) {
        my $x = ($year-1600)/10;
        return (2.19167 * $x*$x - 40.675*$x + 196.58333)/60/60/24;
    }
    else {
        my $tmp = Calendar::Any::Gregorian->new(1, 1, $year)->astro_date - 2382148;
        return ($tmp * $tmp / 41048480.0 - 15)/60/60/24;
    }
}

sub _current_timezone {
    my @gmtime = gmtime(0);
    my @localtime = localtime(0);
    my $mins = 60*$localtime[2] + $localtime[1];
    return ( $localtime[5] == 70 ) ? $mins : $mins - 24*60;
}

1;

__END__

=head1 NAME

Calendar::Any::Util::Solar - Solar event functions

=head1 VERSION

version 0.5

=head1 SYNOPSIS

      use Calendar::Any::Util::Solar qw(next_longitude_date);
      use Calendar::Any::Gregorian;
      my $date = Calendar::Any::Gregorian->new(12, 15, 2006);
      my $next_solstice = Calendar::Any::Gregorian->new(next_longitude_date($date, 30));
      print "The winter solstice is in $next_solstice.\n";

=head1 DESCRIPTION

This library implement the two function in emacs library solar.el. The
function next_longitude_date is used for calculted date that sun's
longitude is a multiple for a degrees. And longitude is used for
calcute sun's longitude at the date.

=head1 AUTHOR

Ye Wenbin <wenbinye@gmail.com>

=cut
