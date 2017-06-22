package Batch::Interpreter::Locale::de_DE;

use v5.10;
use warnings;
use strict;

=head1 NAME

Batch::Interpreter::Locale::de_DE - German locale for Batch::Interpreter

=head1 SYNOPSIS

See Batch::Interpreter.

=cut

our $VERSION = 0.01;

sub format_date {
	my ($self, $year, $month, $day) = @_;
	return sprintf '%02d.%02d.%04d',
		$day, $month, $year;
}

sub format_time_short {
	my ($self, $hour, $min) = @_;
	return sprintf '%02d:%02d',
		$hour, $min;
}

sub format_time {
	my ($self, $hour, $min, $sec, $sec100) = @_;
	return sprintf '%02d:%02d:%02d,%02d',
		$hour, $min, $sec, $sec100;
}

sub format_file_timedate {
	my ($self, $year, $month, $day, $hour, $min) = @_;
	return sprintf '%02d.%02d.%04d  %02d:%02d',
		$day, $month, $year, $hour, $min;
}

sub format_file_timedate_for {
	my ($self, $year, $month, $day, $hour, $min) = @_;
	return sprintf '%02d.%02d.%04d %02d:%02d',
		$day, $month, $year, $hour, $min;
}


my %message = (
	'ECHO is ON.' => 'ECHO ist eingeschaltet (ON).',
	'ECHO is OFF.' => 'ECHO ist ausgeschaltet (OFF).',
	'More? ' => 'Mehr? ',
	'Press a key to continue . . .' => 
		'Drücken Sie eine beliebige Taste . . .',
);

my %strings = (
	message => \%message,
);

sub get_string {
	my ($self, $category, $key) = @_;
	return $strings{$category}{$key};
}

1;

__END__

=head1 AUTHOR

Ralf Neubauer, C<< <ralf at strcmp.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-batch-interpreter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Batch-Interpreter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Batch::Interpreter


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Batch-Interpreter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Batch-Interpreter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Batch-Interpreter>

=item * Search CPAN

L<http://search.cpan.org/dist/Batch-Interpreter/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ralf Neubauer.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

