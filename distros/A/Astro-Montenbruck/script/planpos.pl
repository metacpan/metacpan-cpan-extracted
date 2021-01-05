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
use Astro::Montenbruck::Utils::Display qw/%LIGHT_THEME %DARK_THEME print_data/;

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
    my ($id, $lambda, $beta, $delta, $motion, $obliq, $lst, $lat, $format, $coords, $scheme) = @_;
    my $decimal = uc $format eq 'D';

    state $convert_lambda = convert_lambda($coords, $decimal);
    state $convert_beta   = convert_beta($coords, $decimal);
    state $format_motion  = sub {
        dms_or_dec_str($_[0], decimal => uc $format eq 'D', places => 2, sign => 1 );
    };

    print colored( sprintf('%-10s', $id), $scheme->{table_row_title} );
    print colored( $convert_lambda->($lambda, $beta, $obliq, $lst, $lat), $scheme->{table_row_data} );
    print "   ";
    print colored( $convert_beta->($lambda, $beta, $obliq, $lst, $lat), $scheme->{table_row_data} );
    print "   ";
    print colored( sprintf( '%07.4f', $delta ), $scheme->{table_row_data} );
    print "   ";
    print colored( $format_motion->($motion), $scheme->{table_row_data} );
    print "\n";
}

sub print_header {
    my ($target, $format, $scheme) = @_;
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
    say colored( sprintf($tmpl, @titles), $scheme->{table_col_title} )
}

my $man    = 0;
my $help   = 0;
my $use_dt = 1;
my $time   = local_now()->strftime('%F %T');
my @place;
my $format = 'S';
my $coords = 1;
my $theme  = 'dark';

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
    'theme:s'       => \$theme,

) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

my $scheme = do {
    given (lc $theme) {
        \%DARK_THEME when 'dark';
        \%LIGHT_THEME when 'light';
        default { warn "Unknown theme: $theme. Using default (dark)"; \%DARK_THEME }
    }
};

die "Unknown coordinates format: \"$format\"!" unless $format =~ /^D|S$/i;

@place = @DEFAULT_PLACE unless @place;

my $local = parse_datetime($time);
print_data('Local Time', $local->strftime('%F %T %Z'), scheme => $scheme);
my $utc;
if ($local->time_zone ne 'UTC') {
    $utc   = $local->clone->set_time_zone('UTC');
} else {
    $utc = $local;
}
print_data('Universal Time', $utc->strftime('%F %T'), scheme => $scheme);
print_data('Julian Day', sprintf('%.11f', $utc->jd), scheme => $scheme);

my $t = jd_cent($utc->jd);
if ($use_dt) {
    # Universal -> Dynamic Time
    my $delta_t = delta_t($utc->jd);
    print_data('Delta-T', sprintf('%05.2fs.', $delta_t), scheme => $scheme);
    $t += $delta_t / $SEC_PER_CEN;
}

my ($lat, $lon) = parse_geocoords(@place);
print_data('Place', format_geo($lat, $lon), scheme => $scheme);

# Local Sidereal Time
my $lst = jd2lst($utc->jd, $lon);
print_data('Sidereal Time', hms_str($lst), scheme => $scheme);

# Ecliptic obliquity
my $obliq = obliquity($t);
print_data(
    'Ecliptic Obliquity',
    dms_or_dec_str(
        $obliq,
        places  => 2,
        sign    => 1,
        decimal => $format eq 'D'
    ),
    scheme => $scheme
);
print "\n";

print_header($coords, $format, $scheme);
find_positions(
    $t,
    \@PLANETS,
    sub { print_position(@_, $obliq, $lst, $lat, $format, $coords, $scheme) },
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

The observer's location. Contains 2 elements, space separated, in any order:

=over

=item * latitude in C<DD(N|S)MM> format, B<N> for North, B<S> for South.

=item * longitude in C<DDD(W|E)MM> format, B<W> for West, B<E> for East.

=back

E.g.: C<--place=51N28 0W0> for I<Greenwich, UK>.

=item B<--coordinates> - type and format of coordinates to display:

=over

=item * B<1> - Ecliptical, angular units (default)

=item * B<2> - Ecliptical, zodiac

=item * B<3> - Equatorial, time units

=item * B<4> - Equatorial, angular units

=item * B<5> - Horizontal, time units

=item * B<6> - Horizontal, angular units

=back

=item B<--format> format of numbers:

=over

=item * B<D> decimal: arc-degrees or hours

=item * B<S> sexadecimal: degrees (hours), minutes, seconds

=back

=item B<--theme> color scheme:

=over

=item * B<dark>, default: color scheme for dark consoles

=item * B<light> color scheme for light consoles

=back



=back




=head1 DESCRIPTION

B<planpos> computes planetary positions for current moment or given
time and place.


=cut
