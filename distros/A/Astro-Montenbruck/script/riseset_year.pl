#!/usr/bin/env perl
use 5.22.0;
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib ("$Bin/../lib");

use POSIX qw/strftime/;
use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;
use Astro::Montenbruck::Ephemeris::Planet qw/:ids @PLANETS/;
use Astro::Montenbruck::Time qw/jdnow jd2cal cal2jd jd2unix/;
use Astro::Montenbruck::RiseSet::Constants qw/:events :states/;
use Astro::Montenbruck::RiseSet qw/rst_event/;
use Astro::Montenbruck::Utils::Helpers qw/parse_geocoords format_geo @DEFAULT_PLACE/;

our $VERSION = 0.01;
binmode(STDOUT, ":encoding(UTF-8)");

my $man    = 0;
my $help   = 0;
my $year   =  (localtime())[5] + 1900;
my @place;

# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'     => \$help,
    'man'        => \$man,
    'year:s'     => \$year, 
    'place:s{2}' => \@place,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

@place = @DEFAULT_PLACE unless @place;
my ($lat, $lon);

# first, check if geo-coordinates are given in decimal format
if  (grep(/^[\+\-]?(\d+(\.?\d+)?|(\.\d+))$/, @place) == 2) {
    ($lat, $lon) = @place;
} else {
    ($lat, $lon) = parse_geocoords(@place);
}
say format_geo($lat, $lon);

my $next_jd = cal2jd($year, 1, 1);
my @date;

do {
    @date = jd2cal($next_jd);
    say strftime('%Y-%m-%d', localtime(jd2unix($next_jd)));
    
    for my $pla (@PLANETS) {
        my $func = rst_event(
            planet => $pla,
            date   => \@date,
            phi    => $lat,
            lambda => $lon
        );       
        my %report; 
        for my $evt (@RS_EVENTS) {
            eval {
                $func->(
                    $evt,
                    on_event   => sub {
                        my $jd_evt = shift;
                        $report{$evt} = strftime("%H:%M", localtime(jd2unix($jd_evt)));
                    },
                    on_noevent => sub {
                        $report{$evt} = $_[0];
                    }
                );            
            };
            if ($@) {
                warn $@;
                $report{$evt} = 'error';
            }
        }
        say sprintf(
            '%-12s rise: %s, transit: %s, set: %s',
            $pla, 
            map {$report{$_}} @RS_EVENTS)
    } 
    $next_jd++;  
    say('');     
} while ($date[0] == $year)



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

=item B<--year>

Year, astronomical. Current year in default local time zone If omitted.

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


=head1 DESCRIPTION

Calculate rise, set and transit times of Sun, Moon and the planets for a given year.


=head2 EXAMPLES

    perl ./script/riseset_year.pl --place=56N26 37E09
    perl ./script/riseset_year.pl --place=56N26 37E09 --year=2000

=cut
