#!/perl

use 5.22.0;
use strict;
no warnings qw/experimental/;
use feature qw/switch/;

use utf8;
use FindBin qw/$Bin/;
use lib ("$Bin/../lib");
use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;
use DateTime;
use Term::ANSIColor;

use Readonly;
use Astro::Montenbruck::Utils::Helpers qw/parse_datetime local_now current_timezone/;
use Astro::Montenbruck::Utils::Display qw/%LIGHT_THEME %DARK_THEME print_data/;
use Astro::Montenbruck::Time qw/jd2unix/;
use Astro::Montenbruck::SolEqu qw/:all/;

Readonly::Array our @EVT_NAMES => (
    'March equinox', 'June solstice', 'September equinox', 'December solstice');

my $now = my $now = local_now();

my $help   = 0;
my $man    = 0;
my $year   = $now->year;
my $tzone  = current_timezone(); # $now->strftime('%Z');
my $theme  = 'dark';

# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'     => \$help,
    'man'        => \$man,
    'year:s'     => \$year,
    'theme:s'    => \$theme,
    'timezone:s' => \$tzone,
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

say();
print_data('Year', $year, scheme => $scheme, title_width => 14);
print_data('Time Zone', $tzone, scheme => $scheme, title_width => 14);
say();

for my $evt (@SOLEQU_EVENTS) {
    my $jd = solequ($year, $evt);
    my $dt = DateTime->from_epoch(epoch => jd2unix($jd))->set_time_zone($tzone); 
    print_data(
        $EVT_NAMES[$evt], 
        $dt->strftime('%F %T'), 
        scheme => $scheme, 
        title_width => 18,
        highlited => 1
    );
}

print "\n";


__END__

=pod

=encoding UTF-8

=head1 NAME

phases — calculate date/time of solstices and equinoxes for a given year.

=head1 SYNOPSIS

  solequ [options]

=head1 OPTIONS

=over 4

=item B<--help>

Prints a brief help message and exits.

=item B<--year>

Year, astronomical (zero-year allowed)

  --year=2021

=item B<--timezone>

Time zone short name, e.g.: C<EST>, C<UTC> etc. or I<offset from Greenwich>
in format B<+HHMM> / B<-HHMM>, like C<+0300>.

    --timezone=CET # Central European Time
    --timezone=EST # Eastern Standard Time
    --timezone=UTC # Universal Coordinated Time
    --timezone=GMT # Greenwich Mean Time, same as the UTC
    --timezone=+0300 # UTC + 3h (eastward from Greenwich)

By default, local timezone by default, UTC under Windows.

Please, note: Windows platform does not recognize some time zone names, C<MSK> for instance.
In such cases, use I<offset from Greenwich> format, as described above.


=item B<--theme> color scheme:

=over

=item * B<dark>, default: color scheme for dark consoles

=item * B<light> color scheme for light consoles

=back

=back

=head1 DESCRIPTION

B<solequ> computes solstices and equinoxes for a given year.

=cut
