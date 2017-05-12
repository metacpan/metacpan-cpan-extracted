package App::TimeClock::Weekly::PrinterInterface;

use strict;
use warnings;

=head1 NAME

App::TimeClock::Weekly::PrinterInterface

=head1 DESCRIPTION

Interface class. All printer objects given to
L<App::TimeClock::Weekly::Report> constructor must be derived from
PrinterInterface.

=head1 SYNOPSIS

 package App::TimeClock::Weekly::MyPrinter;
 our @ISA = qw(App::TimeClock::Weekly::PrinterInterface);
 ...
 sub print_header {
     ...
 }
 sub print_day {
     ...
 }
 sub print_footer {
     ...
 }

=head1 METHODS

=over

=cut

=item new()

Creates a new object.

=cut
sub new {
    bless { }, shift;
}

=item _print()

Private print method that uses handle specified by L<_set_ouput_fh> or stdout by default.
All implementing classes should use _print to print instead of print.
This makes testing much easier.

=cut
sub _print {
   my $self = shift;
   my $fh = $self->_get_output_fh;
   print { $fh } @_;
}

=item _get_output_fh()

Get the file handle used by L<_print>.

=cut
sub _get_output_fh {
    # When testing _output will always be set, i.e. skip coverage check of right condition
    # uncoverable condition right
    return $_[0]->{_output}  || \*STDOUT;
}

=item _set_ouput_fh()

Set the file handle used by L<_print>.

=cut
sub _set_output_fh { $_[0]->{_output} = $_[1] }

=item print_header()

Called once at the start of a report.

=cut
sub print_header { shift->_must_implement; };

=item print_week()

Called for each week in the report.

=cut
sub print_week { shift->_must_implement; };

=item print_footer()

Called once at the end of a report.

=cut
sub print_footer { shift->_must_implement; };

sub _must_implement {
    (my $name = (caller(1))[3]) =~ s/^.*:://;
    my ($filename, $line) = (caller(0))[1..2];
    die "You must implement $name() method at $filename line $line";
}
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
