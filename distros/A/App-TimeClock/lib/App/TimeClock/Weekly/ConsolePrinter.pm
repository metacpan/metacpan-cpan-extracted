package App::TimeClock::Weekly::ConsolePrinter;

use strict;
use warnings;

our @ISA = qw(App::TimeClock::Weekly::PrinterInterface);

use POSIX qw(strftime);

use utf8;
binmode STDOUT, ':utf8';

our $hrline =  '+' . ('-' x 62) . '+' . ('-' x 7) . '+';

=head1 NAME

App::TimeClock::Weekly::ConsolePrinter

=head1 DESCRIPTION

Implements the L<App::TimeClock::Weekly::PrinterInterface>. Will print a simple ASCII
format. Suitable for using in a console/terminal.

=head1 METHODS

=over

=cut

=item print_header()

Prints a header including todays date. The header is indented to be
centered above the tables printed by L</print_day()>. Example:

          ======================================
          Weekly Report Mon Mar 19 13:39:06 2012
          ======================================

=cut
sub print_header {
    my $self = shift;
    my $ident = ' ' x 17;
    $self->_print("\n");
    $self->_print("${ident}======================================\n");
    $self->_print("${ident}Weekly Report " . localtime() . "\n");
    $self->_print("${ident}======================================\n\n");
};

=item print_week()

Prints all activities for a week including totals. Is printed in a ACSII
table. Example:

 * Week 11 (2012/03/12 - 2013/03/18) *
 
 +------+------+------+------+------+------+------+-------+
 | Mo12 | Tu13 | We14 | Th15 | Fr16 | Sa17 | Su18 | TOTAL |
 +------+------+------+------+------+------+------+-------+
 | 0.57 | 0.50 | 0.45 | 0.50 | 0.30 |      |      |  2.32 | Lunch
 +------+------+------+------+------+------+------+-------+
 | 2.90 | 3.00 | 7.00 | 7.00 | 6.00 |      |      | 25.90 | MyProject:Estimation
 +------+------+------+------+------+------+------+-------+
 | 4.26 |      |      |      |      |      |      |  4.26 | AnotherProject:Bug...
 -------+------+------+------+------+------+------+-------+
 | 7.73 |      |      |      |      |      |      | 32.48 |
 +------+------+------+------+------+------+------+-------+

=cut
sub print_week {
};

=item print_footer()

Prints the total number of hours worked and the weekly
average. Example:

 TOTAL = 232.50 hours
 PERIOD = 30 days
 AVERAGE = 38.75 hours/week

=cut
sub print_footer {
    my $self = shift;
	$self->_print("Weekly reporting is *not* implemented yet!");
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

Copyright (C) 2012-2014 Søren Lund

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
