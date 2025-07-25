package Array::Merge::Unique;

use 5.006;
use strict;
use warnings;

use Import::Export;
our $VERSION = '1.01';

use base qw/Import::Export/;

our %EX = (
	unique_array => [qw/all/]
);

sub unique_array {
	my (@dataset, %u);
	@dataset = grep { 
		my $k = ref $_ ? $_ + 0 : $_;
		!$u{$k} && do { $u{$k} = 1; $_ } 
	} _aoaoaoa(@_);
	return wantarray ? @dataset : \@dataset;
}

sub _aoaoaoa {
	return map { ref $_ eq 'ARRAY' ? _aoaoaoa(@{ $_ }) : $_ } @_;
}

1;

=head1 NAME

Array::Merge::Unique - Merge those arrays uniquely

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use Array::Merge::Unique qw/unique_array/;

	my $arrayref = unique_array([qw/one two three/], qw/one two/);
	my @array = unique_array([qw/one two three/], qw/one two/);

=head1 EXPORT

=head2 unique_array

This module exports a single method unique_array that accepts multiple Arrays and 
merges them uniquely by value or reference.

	my $ref = { a => "b" };
	my $arrayref = unique_array([qw/one two three/, $ref], qw/one two/, $ref); # qw/one two three/, $ref

=head1 AUTHOR

Robert Acock, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-array-merge-unique at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Array-Merge-Unique>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Array::Merge::Unique

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Array-Merge-Unique>

=item * Search CPAN

L<http://search.cpan.org/dist/Array-Merge-Unique/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017->2025 Robert Acock.

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

1; # End of Array::Merge::Unique
