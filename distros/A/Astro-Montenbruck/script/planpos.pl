#!/perl

use 5.22.0;
use strict;
no warnings qw/experimental/;
use feature qw/state switch/;

use utf8;
use FindBin qw/$Bin/;
use lib ("$Bin/../lib");
use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;
use DateTime;
use Term::ANSIColor;

use Readonly;

use Astro::Montenbruck::Time qw/jd_cent jd2lst $SEC_PER_CEN jd2unix/;
use Astro::Montenbruck::Time::DeltaT qw/delta_t/;
use Astro::Montenbruck::MathUtils qw/frac hms/;
use Astro::Montenbruck::CoCo qw/:all/;
use Astro::Montenbruck::NutEqu qw/obliquity/;
use Astro::Montenbruck::Ephemeris qw/find_positions/;
use Astro::Montenbruck::Ephemeris::Planet qw/@PLANETS/;
use Astro::Montenbruck::Utils::Helpers qw/
    parse_datetime parse_geocoords format_geo hms_str dms_or_dec_str dmsz_str local_now
    @DEFAULT_PLACE/;
use Astro::Montenbruck::Utils::Theme;

sub ecliptic_to_horizontal {
    my ($lambda, $beta, $eps, $lst, $theta) = @_;
    my ($alpha, $delta) = ecl2equ( $lambda, $beta, $eps );
    my $h = $lst * 15 - $alpha; # hour angle, arc-degrees
    equ2hor( $h, $delta, $theta);
}

sub convert_lambda {
    my ($target, $dec) = @_;

    given ($target) {
        sub { dms_or_dec_str( $_[0], decimal => $dec ) }
            when 1;
        sub { dmsz_str( $_[0], decimal => $dec ) }
            when 2;
        sub {
            my ($alpha) = ecl2equ( @_[0..2] );
            hms_str( $alpha / 15, decimal => $dec )
        }   when 3;
        sub {
            my ($alpha) = ecl2equ( @_[0..2] );
            dms_or_dec_str( $alpha, decimal => $dec )
        }   when 4;
        sub {
            my ( $az ) = ecliptic_to_horizontal(@_);
            hms_str( $az / 15, decimal => $dec )
        }   when 5;
        sub {
            my ( $az ) = ecliptic_to_horizontal(@_);
            dms_or_dec_str( $az, decimal => $dec )
        }   when 6;
    }
}

sub convert_beta {
    my ($target, $dec) = @_;

    my $format = sub {
        dms_or_dec_str($_[0], decimal => $dec, places => 2, sign => 1)
    };

    given( $target ) {
        sub {  $format->( $_[1] ) }
            when [1, 2];
        sub {
            my ($alpha, $delta) = ecl2equ( @_[0..2] );
            $format->( $delta )
        }  when [3, 4];
        sub {
            my ( $az, $alt ) = ecliptic_to_horizontal(@_);
            $format->( $alt )
        }  when [5, 6];
    }
}


sub print_position {
    my ($id, $lambda, $beta, $delta, $motion, $obliq, $lst, $lat, $format, $coords, $theme) = @_;
    my $decimal = uc $format eq 'D';
    my $scheme = $theme->scheme;

    state $convert_lambda = convert_lambda($coords, $decimal);
    state $convert_beta   = convert_beta($coords, $decimal);
    state $format_motion  = sub {
        dms_or_dec_str($_[0], decimal => uc $format eq 'D', places => 2, sign => 1 );
    };

    print $theme->decorate( sprintf('%-10s', $id), $scheme->{table_row_title} );
    print $theme->decorate( $convert_lambda->($lambda, $beta, $obliq, $lst, $lat), $scheme->{table_row_data} );
    print "   ";
    print $theme->decorate( $convert_beta->($lambda, $beta, $obliq, $lst, $lat), $scheme->{table_row_data} );
    print "   ";
    print $theme->decorate( sprintf( '%07.4f', $delta ), $scheme->{table_row_data} );
    print "   ";
    print $theme->decorate( $format_motion->($motion), $scheme->{table_row_data} );
    print "\n";
}

sub print_header {
    my ($target, $format, $theme) = @_;
    my $fmt = uc $format;
    my $tmpl;
    my @titles;
    given ($target) {
        when (1) {
            $tmpl = $fmt eq 'S' ? '%-7s   %-11s   %-10s  %-10s %-10s'
                                : '%-7s   %-8s   %-7s  %-10s %-10s';
            @titles = qw/planet lambda beta dist motion/
        }
        when (2) {
            $tmpl = $fmt eq 'S' ? '%-7s   %-11s   %-10s  %-10s %-10s'
                                : '%-7s   %-10s   %-7s  %-10s %-10s';
            @titles = qw/planet zodiac beta dist motion/
        }
        when (3) {
            $tmpl = $fmt eq 'S' ? '%-7s   %-9s   %-10s  %-10s %-10s'
                                : '%-7s   %-6s   %-7s  %-10s %-10s';
            @titles = qw/planet alpha delta dist motion/
        }
        when (4) {
            $tmpl = $fmt eq 'S' ? '%-7s   %-11s   %-10s  %-10s %-10s'
                                : '%-7s   %-8s   %-7s  %-10s %-10s';
            @titles = qw/planet alpha delta dist motion/
        }
        when (5) {
            $tmpl = $fmt eq 'S' ? '%-7s   %-10s  %-9s   %-8s   %-10s'
                                : '%-7s   %-7s  %-6s   %-8s   %-10s';
            @titles = qw/planet azim alt dist motion/
        }
        when (6) {
            $tmpl = $fmt eq 'S' ? '%-7s   %-11s   %-9s   %-8s   %-10s'
                                : '%-7s   %-8s   %-6s   %-8s   %-10s';
            @titles = qw/planet azim alt dist motion/
        }
    }
    say $theme->decorate( sprintf($tmpl, @titles), $theme->scheme->{table_col_title} )
}

my $man    = 0;
my $help   = 0;
my $use_dt = 1;
my $time   = local_now()->strftime('%F %T');
my @place;
my $format = 'S';
my $coords = 1;
my $theme;

# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'        => \$help,
    'man'           => \$man,
    'time:s'        => \$time,
    'place:s{2}'    => \@place,
    'dt!'           => \$use_dt,
    'format:s'      => \$format,
    'coordinates:i' => \$coords,
    'theme:s'       => 
      sub { $theme = Astro::Montenbruck::Utils::Theme->create( $_[1] ) },
    'no-colors'  => 
      sub { $theme = Astro::Montenbruck::Utils::Theme->create('colorless') }

) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

# Initialize default options
$theme //= Astro::Montenbruck::Utils::Theme->create('dark');
die "Unknown coordinates format: \"$format\"!" unless $format =~ /^D|S$/i;

@place = @DEFAULT_PLACE unless @place;

my $local = parse_datetime($time);
$theme->print_data('Local Time', $local->strftime('%F %T %Z'));
my $utc;
if ($local->time_zone ne 'UTC') {
    $utc   = $local->clone->set_time_zone('UTC');
} else {
    $utc = $local;
}
$theme->print_data('Universal Time', $utc->strftime('%F %T'));
$theme->print_data('Julian Day', sprintf('%.11f', $utc->jd));

my $t = jd_cent($utc->jd);
if ($use_dt) {
    # Universal -> Dynamic Time
    my $delta_t = delta_t($utc->jd);
    $theme->print_data('Delta-T', sprintf('%05.2fs.', $delta_t));
    $t += $delta_t / $SEC_PER_CEN;
}

my ($lat, $lon) = parse_geocoords(@place);
$theme->print_data('Place', format_geo($lat, $lon));

# Local Sidereal Time
my $lst = jd2lst($utc->jd, $lon);
$theme->print_data('Sidereal Time', hms_str($lst));

# Ecliptic obliquity
my $obliq = obliquity($t);
$theme->print_data(
    'Ecliptic Obliquity',
    dms_or_dec_str(
        $obliq,
        places  => 2,
        sign    => 1,
        decimal => $format eq 'D'
    )
);
print "\n";

print_header($coords, $format, $theme);
find_positions(
    $t,
    \@PLANETS,
    sub { print_position(@_, $obliq, $lst, $lat, $format, $coords, $theme) },
    with_motion => 1
);
print "\n";



__END__

=pod

=encoding UTF-8

=head1 NAME

planpos - calculate planetary positions for given time and place.

=head1 SYNOPSIS

  planpos [options]

=head1 OPTIONS

=over 4

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--time>

Date and time, either a I<calendar entry> in format C<YYYY-MM-DD HH:MM Z>, or
C<YYYY-MM-DD HH:MM Z>, or a floating-point I<Julian Day>:

  --time="2019-06-08 12:00 +0300"
  --time="2019-06-08 09:00 UTC"
  --time=2458642.875

Calendar entries should be enclosed in quotation marks. Optional B<"Z"> stands for
time zone, short name or offset from UTC. C<"+00300"> in the example above means
I<"3 hours east of Greenwich">.

=item B<--place>

The observer's location. Contains 2 elements, space separated. 

=over

=item * 

latitude in C<DD(N|S)MM> format, B<N> for North, B<S> for South.

=item *

longitude in C<DDD(W|E)MM> format, B<W> for West, B<E> for East.

=back

E.g.: C<--place=51N28 0W0> for I<Greenwich, UK> (the default).

B<Decimal numbers> are also supported. In that case

=over

=item * 

The latitude always goes first

=item * 

Negative numbers represent I<South> latitude and I<East> longitudes. 

=back

C<--place=55.75 -37.58> for I<Moscow, Russian Federation>.
C<--place=40.73 73.935> for I<New-York, NY, USA>.


=item B<--coordinates>: type and format of coordinates to display:

=over

=item * 

B<1> - Ecliptical, angular units (default)

=item * 

B<2> - Ecliptical, zodiac

=item * 

B<3> - Equatorial, time units

=item * 

B<4> - Equatorial, angular units

=item * 

B<5> - Horizontal, time units

=item * 

B<6> - Horizontal, angular units

=back

=item B<--format>: format of numbers:

=over

=item * 

B<D> decimal: arc-degrees or hours

=item * 

B<S> sexadecimal: degrees (hours), minutes, seconds

=back

=item B<--theme>: color theme:

=over

=item * 

B<dark> (default): for dark consoles

=item * 

B<light>: for light consoles

=item * 

B<colorless>: without colors, for terminals that do not support ANSI color codes

=back

=item B<--no-colors>: do not use colors, same as C<--theme=colorless>

=back



=head1 DESCRIPTION

B<planpos> computes planetary positions for current moment or given
time and place.


=cut
