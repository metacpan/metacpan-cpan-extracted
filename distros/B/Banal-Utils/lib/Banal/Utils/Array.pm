#===============================================
package Banal::Utils::Array;

use 5.006;
use utf8;
use strict;
use warnings;
no  warnings qw(uninitialized);

require Exporter;

our @ISA 		= qw(Exporter);
our @EXPORT_OK 	= qw(array1_starts_with_array2);

# Returns true (1) if array1 starts with array2 (via element-by-element equality), false (0) otherwise. 
# The order of elements is important (it ain't a bag). For each compared element, equality can be established either thru string (eq) or numeric (==) comparison.
sub array1_starts_with_array2 {
	my ($array1, $array2) = @_;

	# if array2 is empty, then the result is undefined.
	return 		unless (scalar($array2));
	
	# if array2 has more items than array1, then array1 can't possibly start with array2.
	return 0	if (scalar($array2) > scalar($array1));
		 
	my $k = 0;
	foreach my $e2 (@$array2) {
		no warnings;
		my $e1 = $array1->[$k];	
		
		# Here, we allow both string and numeric equality. It's kind o a relaxed thing. The "no warnings" pragma (above) comes in handy.
		return 0 unless (($e1 eq $e2) || ($e1 == $e2));
		$k++;
	}
	return 1;
}




1;

__END__

=head1 NAME

Banal::Utils::Array - Totally banal and trivial utilities for arrays and lists.


=head1 SYNOPSIS

    use Banal::Utils::Array qw(array1_starts_with_array2);
    
    $a1 = ["greetings","to", "the", "world"];
    $a2 = ["greetings","to"];
    
    if (array1_starts_with_array2($a1, $a2)) {
    	print "Hello World!\n";
    }
    
    ...

=head1 EXPORT

None by default.

=head1 EXPORT_OK

array1_starts_with_array2


=head1 SUBROUTINES / FUNCTIONS

=head2 array1_starts_with_array2($a1, $a2)

Returns true (1) if array1 starts with array2 (via element-by-element equality), false (0) otherwise. 
The order of elements is important (it ain't a bag). 
For each compared element, equality can be established either thru string (eq) or numeric (==) comparison.



=head1 AUTHOR

"aulusoy", C<< <"dev (at) ulusoy.name"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-banal-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Banal-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Banal::Utils::Array


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Banal-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Banal-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Banal-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Banal-Utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 "aulusoy".

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

1; # End of Banal::Utils::Array

