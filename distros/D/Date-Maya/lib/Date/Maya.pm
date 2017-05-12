package Date::Maya;

use 5.006;

use strict;
use integer;
use warnings;
no  warnings 'syntax';
use Exporter;

our $VERSION     = '2010011301';


our @ISA         = qw (Exporter);
our @EXPORT      = qw (julian_to_maya maya_to_julian);
our @EXPORT_OK   = qw (MAYA_EPOCH1 MAYA_EPOCH2 MAYA_EPOCH3 maya_epoch);
our %EXPORT_TAGS =    (MAYA_EPOCH => [qw /MAYA_EPOCH1 MAYA_EPOCH2
                                                      MAYA_EPOCH3/]);


use constant MAYA_EPOCH1 => 584285;  # 13 Aug 3114 BC, Gregorian.
use constant MAYA_EPOCH2 => 584283;  # 11 Aug 3114 BC, Gregorian.
use constant MAYA_EPOCH3 => 489384;  # 15 Oct 3374 BC, Gregorian.

my $epoch = MAYA_EPOCH1;

sub maya_epoch ($) {$epoch = shift;}


my $date_parts   = [
    [kin         =>     20],
    [unial       =>     18],
    [tun         =>     20],
    [katun       =>     20],
    [baktun      =>     20],
    [pictun      =>     20],
    [calabtun    =>     20],
    [kinchiltun  =>     20],
    [alautun     =>  undef],
];

my $max_baktun   = 13;

my @tzolkin = qw /Ahau Imix Ik Akbal Kan Chicchan Cimi Manik Lamat Muluc
                  Oc Chuen Eb Ben Ix Men Cib Caban Etznab Caunac/;

my $tzolkin_sweek_length = 13;
my $tzolkin_sweek_offset =  4;

my @haab    = qw /Pop Uo Zip Zotz Tzec Xul Yaxkin Mol Chen Yax Zac Ceh
                  Mac Kankin Muan Pax Kayab Cumku/;

my $haab_month_length =   20;
my $haab_uayeb_length =    5;
my $haab_year_length  = $haab_month_length * @haab;
my $haab_fyear_length = $haab_year_length  + $haab_uayeb_length;
my $haab_offset       =  348;  # 8 Cumku.


sub julian_to_maya ($) {
    die "No argument to julian_to_maya\n" unless @_;

    my $julian = shift;

    die "Undefined argument to julian_to_maya\n" unless defined $julian;
    die "Illegal argument `$julian' to julian_to_maya\n" if $julian =~ /\D/;

    my $days   = $julian - $epoch;
    die "Cannot deal with dates before epoch.\n" if $days < 0;

    # Calculation of the Long Count.
    my @results;

    foreach my $part (@$date_parts) {
        push @results  => $days % $part -> [1];
        last if $part  -> [0] eq "baktun";
        $days /= $part -> [1];
    }

    @results       = reverse @results;
    $results [0]  %= $max_baktun;
    $results [0]   = $max_baktun if $results [0] == 0;

    my $long_count = join "." => @results;

    unless (wantarray) {
        return $long_count;
    }


    # Calculation of the Tzolkin.
    my $tzolkin_day = ($julian - $epoch + $tzolkin_sweek_offset) %
                                          $tzolkin_sweek_length;
       $tzolkin_day =  $tzolkin_sweek_length if $tzolkin_day == 0;

    my $tzolkin     = "$tzolkin_day $tzolkin[$results[4]]";


    # Calculation of the Haab.
    my $haab_y_day = ($julian - $epoch + $haab_offset) % $haab_fyear_length;
    my $haab;
    if ($haab_y_day >= $haab_year_length) {
        $haab = ($haab_y_day - $haab_year_length) . " Uayeb";
    }
    else {
        $haab =  join " " => ($haab_y_day % $haab_month_length),
                       $haab [$haab_y_day / $haab_month_length];
    }

    ($long_count, $tzolkin, $haab);
}



sub maya_to_julian ($) {
    die "Failed to supply argument to maya_to_julian\n" unless @_;

    my $maya = shift;

    die "Undefined argument to maya_to_julian\n" unless defined $maya;

    my @parts = split /\./ => $maya;
    die "Illegal argument `$maya' to maya_to_julian\n"
         unless 5 == @parts && !grep {/\D/} @parts;
    # Normalize the baktun.
    $parts [0] = 0 if $parts [0] == $max_baktun;

    my $julian = $epoch;

    my $mod = 1;
    my $i   = 0;
    foreach my $part (reverse @parts) {
        if ($part >= $date_parts -> [$i] -> [1]) {
            die "Out of bounds argument to maya_to_julian\n";
        }
        $julian += $part * $mod;
        $mod    *= $date_parts -> [$i] -> [1];
        $i ++;
    }

    $julian;
}

__END__

=pod

=head1 NAME

Date::Maya  --  Translate between Julian days and Maya days.

=head1 SYNOPSIS

    use Date::Maya;

    my  $long_count             = julian_to_maya 2451432;
    my ($long, $tzolkin, $haab) = julian_to_maya 2451432;
    my  $julian                 = maya_to_julian '12.19.6.9.9';

=head1 DESCRIPTION

For an extensive description of both the Maya calendar and Julian days,
see the calendar faq [1].

This module presents routines to calculate the Mayan day from a Julian
day, and a Julian day from a Mayan day. The Mayan calendar has different
dating systems, the Long Count (which cycles every 5125 years), the
Tzolkin (260 days) and the Haab (365 days). The Long Count consists
of quintuple of numbers (really a mixed base 20/18 number), while the
Tzolkin and the Haab consist of day numbers and week or month names. In
the Tzolkin, both the week number and week name change from day to day;
the week number cycles through 1 to 13, while there are 20 week names to
cycle through. This gives a period of 260 days. The Haab has 18 months,
of each 20 days, numbered 0 to 19. A new month is only started after
reaching day 19. At the end of the 360 days, there are 5 Uayeb days. In
the Long Count, all the numbers of the quintuple are 0 to 19 or 0 to 17,
except the first, (the number of I<baktuns>), which goes from 1 to 13;
with 13 serving as 0.

By default, Date::Maya exports two subroutines, C<julian_to_maya> and
C<maya_to_julian>. C<julian_to_maya> takes a Julian day as argument, and
returns the Long Count date in scalar context. In list context, it returns
the Long Count date, the Tzolkin date, and the Haab date. C<maya_to_julian>
takes a Long Count date as argument, and returns a Julian day.

=head2 EPOCH AND ROLL OVER

It is unclear when the epoch of the Mayan calendar occurred. Three dates
are mentioned as candidates, S<13 Aug 3114 BC>, S<11 Aug 3114 BC>, and
S<15 Oct 3374 BC>. Unless changed, this module assumes S<13 Aug 3114> as
the epoch.

To change the epoch, import the function C<maya_epoch>, and call it with the
Julian date that should be the epoch. Constants C<MAYA_EPOCH1>, C<MAYA_EPOCH2>
and C<MAYA_EPOCH3> can be imported, which will have the Julian days for
S<13 Aug 3114 BC>, S<11 Aug 3114 BC>, and S<15 Oct 3374 BC> as values.
The three constants can be imported at once by using the C<:MAYA_EPOCH> tag.

The Mayan calendar is cyclic, with a period of just over 5125 years. This
means that if the epoch was in S<Aug 3114 BC>, the calendar will roll over
in S<Dec 2012 AD>. If the epoch was in S<3374 BC>, the roll over has occured
over 200 years ago. Since the calendar is cyclic, the C<maya_to_julian> function
is not unique. We will however return only one date, and that is the first
Julian day matching the Long Count date on or after the choosen epoch.

The Mayan Long Count calendar rolls over after 1872000 days.

=head1 REFERENCES

=over 4

=item [1]

Tondering, Claus: I<FREQUENTLY ASKED QUESTIONS ABOUT CALENDARS>
L<< http://www.tondering.dk/claus/calendar.html >>

=back

=head1 SEE ALSO

Sources are on github: L<< git://github.com/Abigail/date--maya.git >>.

L<< DateTime::Calendar::Mayan >> is a plugin for the C<< DateTime >>
framework.

=head1 AUTHOR

This package was written by Abigail, L<< mailto:date-maya@abigail.be >>.

=head1 COPYRIGHT AND LICENSE

This package is copyright 1999 - 2009 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
