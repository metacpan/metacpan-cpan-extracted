package App::calendr;

$App::calendr::VERSION   = '0.23';
$App::calendr::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

App::calendr - Application to display supported Calendar.

=head1 VERSION

Version 0.23

=cut

use 5.006;
use Data::Dumper;
use App::calendr::Option;
use Module::Pluggable
    search_path => [ 'Calendar' ],
    require     => 1,
    inner       => 0,
    max_depth   => 2;

use Moo;
use namespace::clean;

our $DEFAULT_CALENDAR = 'Gregorian';
our $FAILED_CALENDARS = {};

use Types::Standard -all;
use MooX::Options;
with 'App::calendr::Option';


=head1 DESCRIPTION

It provides simple  command  line  interface  to the package L<App::calendr>. The
distribution contains a script C<calendr>, using package L<App::calendr>.

=head1 SYNOPSIS

You can list all command line options by giving C<--help> flag.The C<--name> flag
is only  mandatory. Rest of all are  optionals. If C<--month> flag is passed then
the C<--year> flag  becomes  mandatory and vice versa. In case neither of them is
passed in then it would look for C<--gdate>/C<--jday> flag and accordingly act on
it. In case none C<flag> passed in it would show the current calendar month.

    $ calendr --help

    USAGE: calendr [-h] [long options...]

        --name: String
           Calendar name e.g. Bahai,Gregorian,Hebrew,Hijri,Julian,Persian,Saka.
           Default is Gregorian.

        --month: String
           Month number/name e.g. 1,2,3... or January,February...

        --year: Int
           Year number (3/4 digits)

        --gdate: String
           Gregorian date (YYYY-MM-DD)

        --jday: Int
           Julian day

        --as_svg:
           Generate calendar in SVG format

        --list_month_names:
           List calendar month names

        --usage:
           show a short help message

        -h:
           show a compact help message

        --help:
           show a long help message

        --man:
           show the manual

=head1 SUPPORTED CALENDARS

The following supported calendars can be installed individually.

=over 4

=item * L<Calendar::Bahai>

=item * L<Calendar::Gregorian>

=item * L<Calendar::Hebrew>

=item * L<Calendar::Hijri>

=item * L<Calendar::Julian>

=item * L<Calendar::Persian>

=item * L<Calendar::Saka>

=back

Or they all can be installed in one go using L<Task::Calendar> package.

    $ cpanm Task::Calendar

=cut

sub BUILD {
    my ($self) = @_;

    my $plugins = [ plugins ];
    foreach my $plugin (@$plugins) {
        my $cal = _load_calendar($plugin);
        if (defined $cal) {
            my $inst_ver = ${plugin}->VERSION;
            my $min_ver  = $cal->{min_ver};
            my $cal_name = $cal->{name};
            if ($inst_ver >= $min_ver) {
                $self->{calendars}->{$cal_name} = $plugin->new;
            }
            else {
                $FAILED_CALENDARS->{$cal_name} = {
                    cal_name => $cal_name,
                    min_ver  => $min_ver,
                    inst_ver => $inst_ver,
                };
            }
        }
    }
}

=head1 METHODS

=head2 run()

This  is the only method provided by package L<App::calendr>. It does not  expect
any parameter. Here is the code from the supplied C<calendr> script.

    use strict; use warnings;
    use App::calendr;

    App::calendr->new_with_options->run;

=cut

sub run {
    my ($self) = @_;

    my $month = $self->month;
    my $year  = $self->year;
    my $name  = $self->name || $DEFAULT_CALENDAR;

    my $supported_calendars = _supported_calendars();
    my $supported_cal = $supported_calendars->{uc($name)};
    die "ERROR: Unsupported calendar [$name] received.\n" unless defined $supported_cal;

    my $calendar = $self->get_calendar($name);
    # Is supported calendar installed?
    if (!defined $calendar) {
        # Is the calendar failed version pass min ver?
        if (exists $FAILED_CALENDARS->{$supported_cal->{name}}) {
            my $min_ver  = $FAILED_CALENDARS->{$supported_cal->{name}}->{min_ver};
            my $inst_ver = $FAILED_CALENDARS->{$supported_cal->{name}}->{inst_ver};
            my $cal_name = $FAILED_CALENDARS->{$supported_cal->{name}}->{cal_name};
            die sprintf("ERROR: Found %s v%s but required v%s.\n", $cal_name, $inst_ver, $min_ver);
        }

        die "ERROR: Calendar [$name] is not installed.\n";
    }

    if (defined $month || defined $year) {
        if (defined $month) {
            die "ERROR: Missing year.\n" unless defined $year;
        }
        else {
            die "ERROR: Missing month.\n" if defined $year;
        }

        if (defined $month) {
            if (ref($calendar) eq 'Calendar::Hebrew') {
                $calendar->date->validate_hebrew_month($month, $year);
            }
            else {
                $calendar->date->validate_month($month, $year);
            }
            if ($month =~ /^[A-Z]+$/i) {
                $month = $calendar->date->get_month_number($month);
            }
            $calendar->month($month);
        }

        if (defined $year) {
            $calendar->date->validate_year($year);
            $calendar->year($year);
        }
    }
    elsif (defined $self->gdate) {
        my $gdate = $self->gdate;
        die "ERROR: Invalid gregorian date '$gdate'.\n"
            unless ($gdate =~ /^\d{4}\-\d{2}\-\d{2}$/);

        my ($year, $month, $day) = split /\-/, $gdate, 3;
        print $calendar->from_gregorian($year, $month, $day) and return;
    }
    elsif (defined $self->jday) {
        my $julian_day = $self->jday;
        die "ERROR: Invalid julian day '$julian_day'.\n"
            unless ($julian_day =~ /^\d+\.?\d?$/);

        print $calendar->from_julian($julian_day) and return;
    }
    elsif (defined $self->list_month_names) {
        my $month_names = $calendar->date->months;
        shift @$month_names; # Remove empty entry.
        print join("\n", @$month_names), "\n" and return;
    }

    if (defined $self->as_svg) {
        print $calendar->as_svg, "\n";
    }
    else {
        print $calendar, "\n";
    }
}

sub get_calendar {
    my ($self, $name) = @_;

    return unless defined $name;
    my $supported_cals = _supported_calendars();
    my $cal_pkg = $supported_cals->{uc($name)}->{name};
    return $self->{calendars}->{$cal_pkg} if exists $self->{calendars}->{$cal_pkg};
    return;
}

#
#
# PRIVATE METHODS

sub _load_calendar {
    my ($plugin) = @_;
    return unless defined $plugin;

    my $calendars = _supported_calendars();
    foreach my $key (keys %$calendars) {
        return $calendars->{$key} if ($calendars->{$key}->{name} eq $plugin);
    }
    return;
}

sub _supported_calendars {

    return {
        'BAHAI'     => { name => 'Calendar::Bahai',     min_ver => 0.46 },
        'GREGORIAN' => { name => 'Calendar::Gregorian', min_ver => 0.15 },
        'HEBREW'    => { name => 'Calendar::Hebrew',    min_ver => 0.03 },
        'HIJRI'     => { name => 'Calendar::Hijri',     min_ver => 0.33 },
        'JULIAN'    => { name => 'Calendar::Julian',    min_ver => 0.01 },
        'PERSIAN'   => { name => 'Calendar::Persian',   min_ver => 0.35 },
        'SAKA'      => { name => 'Calendar::Saka',      min_ver => 1.34 },
    };
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/App-calendr>

=head1 BUGS

Please  report any bugs or feature requests to C<bug-app-calendr at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-calendr>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::calendr

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-calendr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-calendr>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-calendr>

=item * Search CPAN

L<http://search.cpan.org/dist/App-calendr/>

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

1; # End of App::calendr
