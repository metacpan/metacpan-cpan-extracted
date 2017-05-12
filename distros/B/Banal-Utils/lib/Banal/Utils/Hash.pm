#===============================================
package Banal::Utils::Hash;

use 5.006;
use utf8;
use strict;
use warnings;
no  warnings qw(uninitialized);

require Exporter;

our @ISA 		= qw(Exporter);
our @EXPORT_OK 	= qw(get_inner_hash_value);


use Scalar::Util qw(reftype);
use Carp;


#-----------------------------------------------
# get_inner_hash_value($hash, @$keys)	-- 	Given a list of keys, get the associated "value" in an inner hash. 
#											Assumes that all inner levels (except the obtained value) are also HASH references.
#...............................................
# Function (NOT a method)
#-----------------------------------------------
sub get_inner_hash_value {
	my $hash	= shift;
	my $keys	= [@_];
	my $key		= pop @$keys;
	
	my $h = $hash;
	foreach my $k (@$keys) {
		return undef unless (reftype($h) eq 'HASH');
		if (exists ($h->{$k})) {
			$h = $h->{$k};
		}else {
			return undef;
		}
	} 
	
	if (exists ($h->{$key})) {
		return $h->{$key};
	}
	return undef;
}





1;

__END__

=head1 NAME

Banal::Utils::Hash - Totally banal and trivial hash utilities.


=head1 SYNOPSIS

    use Banal::Utils::Hash qw(get_inner_hash_value);
    
    ...

=head1 EXPORT

None by default.

=head1 EXPORT_OK

=head2 get_inner_hash_value


=head1 SUBROUTINES / FUNCTIONS

=head2 get_inner_hash_value($hash, @$keys)

Given a list of keys, get the associated "value" in an inner hash in a hash of hashes.
Assumes that all inner levels (except the obtained value) are also HASH references.

See the C<banal_get_data()> function in L<Banal::Utils::Data> for a much more sophisticated routine for similar purposes and beyond. 


=head1 AUTHOR

"aulusoy", C<< <"dev (at) ulusoy.name"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-banal-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Banal-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Banal::Utils::Hash


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

1; # End of Banal::Utils::Hash

