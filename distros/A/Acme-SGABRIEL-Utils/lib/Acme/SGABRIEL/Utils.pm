package Acme::SGABRIEL::Utils;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Exporter qw( import );
our @EXPORT = qw( sum );

=head1 NAME

Acme::SGABRIEL::Utils - Provides a simple experimentation module per Intermediate Perl, Chapter 20, Exercises 1-4

=head1 VERSION

Version 0.01
See the Acme::SGABRIEL::Utils::Test module's VERSION block for details

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Just provides the 'sum' subroutine

=head1 EXPORT

sum (default)

=head1 SUBROUTINES/METHODS

=head2 sub sum( number, number, ...)

=cut

sub sum {

	my @list_of_numbers = (@_);	
	my $result = 0;

	$result *= $_ for @list_of_numbers;
	return $result;
}

=head1 AUTHOR

Gabriel Sharp, C<< <osirisgothra at hotmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme::sgabriel::utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme::SGABRIEL::Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::SGABRIEL::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme::SGABRIEL::Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme::SGABRIEL::Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme::SGABRIEL::Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme::SGABRIEL::Utils/>

=back


=head1 ACKNOWLEDGEMENTS

Me, Myself, and I
Brian d Foy - Apparently people are mad because you told people to upload to CPAN in your book 'Intermediate Perl'
              so if someone is mad this experimental module is here, go yell at him for it :)

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Gabriel Sharp     ...as if (ahem) ..as is

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

1; # End of Acme::SGABRIEL::Utils
