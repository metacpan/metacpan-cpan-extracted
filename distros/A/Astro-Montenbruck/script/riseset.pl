#!/perl

use 5.22.0;
use strict;
no warnings qw/experimental/;
use feature qw/state switch/;

use utf8;
use FindBin qw/$Bin/;
use lib ("$Bin/lib", "$Bin/../lib");
use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;
use DateTime;
use Term::ANSIColor;

use Readonly;

use Astro::Montenbruck::MathUtils qw/frac hms/;
use Astro::Montenbruck::Ephemeris::Planet qw/@PLANETS/;
use Astro::Montenbruck::Time qw/jd2unix cal2jd/;
use Astro::Montenbruck::RiseSet::Constants qw/:events :twilight/;
use Astro::Montenbruck::RiseSet qw/:all/;
use Helpers qw/parse_datetime parse_geocoords format_geo hms_str
               $LOCALE @DEFAULT_PLACE/;
use Display qw/%LIGHT_THEME %DARK_THEME print_data/;

binmode(STDOUT, ":encoding(UTF-8)");

Readonly::Hash our %TWILIGHT_TITLE => (
    $EVT_RISE => 'Dawn',
    $EVT_SET  => 'Dusk',
);

sub process_planet {
    my ($id, $func, $scheme, $tzone) = @_;

    print colored( sprintf('%-8s', $id), $scheme->{table_row_title} );

    for my $evt (@RS_EVENTS) {
        $func->(
            $evt,
            on_event   => sub {
                my $jd = shift; # Standard Julian date
                my $dt = DateTime->from_epoch(epoch => jd2unix($jd))
                                 ->set_time_zone($tzone);
                print colored(
                    $dt->strftime('%T'),
                    $scheme->{table_row_data}
                );
                print "   ";
            },
            on_noevent => sub {
                print colored(
                    sprintf('%-8s', ' — '),
                    $scheme->{table_row_error}
                );
                print " ";
            }
        );
    }
    print "\n"
}

# date   => [ $utc->year, $utc->month, $utc->day ],
# phi    => $lat,
# lambda => $lon,
# type   => $twilight,
# scheme => $scheme,
# timezone => $local->time_zone
sub process_twilight {
    my %arg = @_;
    my $date = $arg{date};

    my %res;
    twilight(
        %arg,
        on_event => sub {
            my ( $evt, $ut ) = @_;
            my $jd = cal2jd($date->[0], $date->[1], int($date->[2]) + $ut / 24);
            my $dt = DateTime->from_epoch(epoch => jd2unix($jd))
                             ->set_time_zone($arg{timezone});
            $res{$evt} = $dt;
        },
        on_noevent => sub{}
    );

    for my $evt ($EVT_RISE, $EVT_SET) {
        if (exists $res{$evt}) {
            print_data(
                $TWILIGHT_TITLE{$evt},
                $res{$evt}->strftime('%T'),
                scheme      => $arg{scheme},
                title_width => 7
            );
        }
        else {
            print_data(
                $TWILIGHT_TITLE{$evt},
                ' — ',
                scheme      => $arg{scheme},
                title_width => 7
            );
        }
    }
}

my $now = DateTime->now()->set_locale($LOCALE);

my $man     = 0;
my $help    = 0;
my $date    = $now->strftime('%F');
my $tzone   = $now->strftime('%z');
my @place;
my $theme    = 'dark';
my $twilight = $TWILIGHT_NAUTICAL;


# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'     => \$help,
    'man'        => \$man,
    'date:s'     => \$date,
    'timezone:s' => \$tzone,
    'place:s{2}' => \@place,
    'theme:s'    => \$theme,
    'twilight:s' => \$twilight
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

@place = @DEFAULT_PLACE unless @place;

my $scheme = do {
    given (lc $theme) {
        \%DARK_THEME  when 'dark';
        \%LIGHT_THEME when 'light';
        default { warn "Unknown theme: $theme. Using default (dark)"; \%DARK_THEME }
    }
};

my $local = parse_datetime($date);
$local->set_time_zone($tzone) if defined($tzone);
print_data(
    'Date',
    $local->strftime('%F %Z'),
    scheme      => $scheme,
    title_width => 7
);
my $utc = $local->time_zone ne 'UTC' ? $local->clone->set_time_zone('UTC')
                                     : $local;

my ($lat, $lon);

# first, check if geo-coordinates are given in decimal format
if  (grep(/^[\+\-]?(\d+(\.?\d+)?|(\.\d+))$/, @place) == 2) {
    ($lat, $lon) = @place;
} else {
    ($lat, $lon) = parse_geocoords(@place);
}

print_data(
    'Place',
    format_geo($lat, $lon),
    scheme      => $scheme,
    title_width => 7
);
print "\n";
print colored(
    "        rise       transit    set     \n",
    $scheme->{table_row_title}
);
for (@PLANETS) {
    my $func = rst_event(
        planet => $_,
        date   => [ $utc->year, $utc->month, $utc->day ],
        phi    => $lat,
        lambda => $lon
    );
    process_planet($_, $func, $scheme, $local->time_zone)
}

say colored("\nTwilight ($twilight)\n", $scheme->{data_row_title});
process_twilight(
    date   => [ $utc->year, $utc->month, $utc->day ],
    phi    => $lat,
    lambda => $lon,
    type   => $twilight,
    scheme => $scheme,
    timezone => $local->time_zone
);

print "\n";


__END__

=pod

=encoding UTF-8

=head1 NAME

riseset — calculate rise, set and transit times of Sun, Moon and the planets.


=head1 SYNOPSIS

  riseset [options]

=head1 OPTIONS

=over 4

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--date>

Calendar date in format C<YYYY-MM-DD>, e.g.:

  --date=2019-06-08

Current date in default local time zone If omitted.

=item B<--timezone>

Time zone short name, e.g.: C<EST>, C<UTC> etc. or I<offset from Greenwich>
in format B<+HHMM> / B<-HHMM>, like C<+0300>.

    --timezone=CET # Central European Time
    --timezone=EST # Eastern Standard Time
    --timezone=UTC # Universal Coordinated Time
    --timezone=GMT # Greenwich Mean Time, same as the UTC
    --timezone=+0300 # UTC + 3h (eastward from Greenwich)

By default, local timezone by default, UTC under Windows.

Please, note: Windows platform does not recognize some time zone names, 
C<MSK> for instance. In such cases, use 
I<offset from Greenwich> format, as described above.


=item B<--place>

The observer's location. Contains 2 elements, space separated. 

=over

=item * latitude in C<DD(N|S)MM> format, B<N> for North, B<S> for South.

=item * longitude in C<DDD(W|E)MM> format, B<W> for West, B<E> for East.

=back

E.g.: C<--place=51N28 0W0> for I<Greenwich, UK> (the default).

B<Decimal numbers> are also supported. In that case

=over

=item * The latitude always goes first

=item * Negative numbers represent I<South> latitude and I<East> longitudes. 

=back

C<--place=55.75 -37.58> for I<Moscow, Russian Federation>.
C<--place=40.73 73.935> for I<New-York, NY, USA>.


=item B<--twilight> type of twilight:

=over

=item * B<civil>

=item * B<nautical> (default)

=item * B<astronomical>

=back


=item B<--theme> color scheme:

=over

=item * B<dark>, default: color scheme for dark consoles

=item * B<light> color scheme for light consoles

=back

=back


=head1 DESCRIPTION

Calculate rise, set and transit times of Sun, Moon and the
planets. The program also calculates twilight, nautical by default. To calculate
civil or astronomical twilight, use C<--twilight> option.

All times are given in the same time zone which was provided by C<--time> option,
or the default system time zone.

There are some conditions when an event can not be calculated. For instance,
when celestial body is I<circumpolar> or I<never rises>. In such cases there is
a dash (C<—>) instead of time.

=head2 EXAMPLES

    perl ./script/riseset.pl --place=56N26 37E09 --twilight=civil
    perl ./script/riseset.pl --place=56N26 37E09 --date=1968-02-11 --timezone=UTC

=cut
