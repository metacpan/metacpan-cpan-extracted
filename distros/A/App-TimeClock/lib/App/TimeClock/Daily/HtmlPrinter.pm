package App::TimeClock::Daily::HtmlPrinter;

use strict;
use warnings;

our @ISA = qw(App::TimeClock::Daily::PrinterInterface);

use POSIX qw(strftime);

=head1 NAME

App::TimeClock::Daily::HtmlPrinter

=head1 DESCRIPTION

Implements the L<App::TimeClock::Daily::PrinterInterface>. Will print a
(simple) HTML report with embedded (CSS) styling.

=head1 METHODS

=over

=cut

=item print_header()

Prints a standard HTML header, i.e. DOCTYPE followed by an opening html
tag and a head tag. The head will contain a title with todays date and
an embedded (css) style. A body tag will open and an h1 header with
todays day will be printed. The body and html tags will be closed in the
L</print_footer()> method.

=cut
sub print_header {
    my $self = shift;
    my $title = "Daily Report " . localtime();

    $self->_print(<< "EOD");
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><meta http-equiv='Content-Type' content='text/html;charset=utf-8'/><title>$title</title>
<style type='text/css'>
html, body { margin: 0; padding: 0; border: 0; }
body { background:#fff; color:#000; margin: 1em 0 0 1em; }
table { border-collapse: collapse; width: 80ex; }
th, td { margin:0; border:1px solid #000;padding:0.2em; }
caption { margin-top: 1em; }
tr, caption { text-align:left; }
.totals { border: 2px solid #000; background: #9cf; width: 40ex; padding: 0.5em;}
.totals, caption { font-size: 110%; font-weight: bold; }
th { background: #58b; color: #fff; }
tr:nth-child(even) td { background: #dfe; }
tr:nth-child(odd) td { background: #def; }
th.N, td.N { width: 10%; text-align: right; }
</style></head><body><h1>$title</h1>
EOD

};

=item print_day()

Prints all activities for a day including a total. Is printed in a
standard HTML table.

=cut
sub print_day {
    my ($self, $date, $start, $end, $work, %projects) = (@_);
    my ($year, $mon, $mday) = split(/\//, $date);
    my $wday = substr(strftime("%a", 0, 0, 0, $mday, $mon-1, $year-1900),0,3);

    $self->_print(sprintf("<table><caption>%3s %s (%s - %s)</caption>\n", $wday, $date, $start, $end));
    $self->_print(sprintf("<tr><th>Total Daily Hours</th><th class='N'>%5.2f</th></tr>\n", $work));

    foreach my $k (sort keys %projects) {
        $self->_print(sprintf("<tr><td>%-60s</td><td class='N'>%5.2f</td></tr>\n", $k, $projects{$k}));
    }
    $self->_print("</table>\n");
};

=item print_footer()

Prints the total number of hours worked and the daily average and closes
the body and html tags.

=cut
sub print_footer {
    my ($self, $work_year_to_date, $day_count) = (@_);
    $self->_print("<p class='totals'>");
    $self->_print(sprintf("TOTAL = %.2f<br/>", $work_year_to_date));
    $self->_print(sprintf("PERIOD = %d days<br/>", $day_count));
    $self->_print(sprintf("AVG. DAY = %.2f<br/>", $day_count > 0 ? $work_year_to_date / $day_count : 0));
    $self->_print("</p>\n");
    $self->_print("</body></html>\n");
};
1;

=back

=for text
=encoding utf-8
=end

=head1 AUTHOR

Søren Lund, C<< <soren at lund.org> >>

=head1 SEE ALSO

L<timeclock.pl>

=head1 COPYRIGHT

Copyright (C) 2012-2015 Søren Lund

This file is part of App::TimeClock.

App::TimeClock is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

App::TimeClock is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with App::TimeClock.  If not, see <http://www.gnu.org/licenses/>.
