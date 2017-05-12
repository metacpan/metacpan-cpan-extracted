package App::TimeClock::Daily::CsvPrinter;

use strict;
use warnings;

our @ISA = qw(App::TimeClock::Daily::PrinterInterface);

use POSIX qw(strftime);

=head1 NAME

App::TimeClock::Daily::CsvPrinter

=head1 DESCRIPTION 

Implements the L<App::TimeClock::Daily::PrinterInterface>. Will print total
for each day in a comma separated format.

=head1 METHODS

=over

=cut

=item print_header()

There's no header when print CSV. This is an empty sub.

=cut
sub print_header {};

=item print_day()

Prints totals for each day. Five fields are printed: week day, date,
start time, end time and total hours worked. Example:

 "Mon","2012/03/12","08:21:16","16:05:31",7.732222

=cut
sub print_day {
    my ($self, $date, $start, $end, $work, %projects) = (@_);
    my ($year, $mon, $mday) = split(/\//, $date);
    my $wday = substr(strftime("%a", 0, 0, 0, $mday, $mon-1, $year-1900),0,3);

    $self->_print(sprintf('"%s","%s","%s","%s",%f' . "\n",$wday, $date, $start, $end, $work));
};

=item print_footer()

There's no footer when print CSV. This is an empty sub.

=cut
sub print_footer {};
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
