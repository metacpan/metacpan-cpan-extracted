package Bijection;
use 5.006; use strict; use warnings; our $VERSION = '0.01';
use Import::Export; use base qw/Import::Export/;
use Carp qw/croak/;
our %EX = (biject => [qw/all/], inverse => [qw/all/]);

our (@ALPHA, $COUNT, %INDEX);
BEGIN {
	@ALPHA = qw/b c d f g h j k l m n p q r s t v w x y z B C D F G H J K L M N P Q R S T V W X Y Z 0 1 2 3 4 5 6 7 8 9/;
	$COUNT = @ALPHA;
	my $index = -1;
	%INDEX = map +( $_ => ++$index ), @ALPHA; 
}

sub biject {
	my ($id, $out) = @_;
	croak "id to encode must be an integer and non-negative" unless (($id =~ m/^\d+$/ || $id > 0) and $id += $COUNT);
	do { $out .= $ALPHA[($id % $COUNT)]; 1} and $id = int($id/$COUNT) while ($id > 0);
	reverse ($out || $ALPHA[0]);
}

sub inverse {
	my ($out, $id) = (@_, 0);
    defined $INDEX{$_} && do { $id = $id * $COUNT + $INDEX{$_}; 1; } or croak "invalid character $_ in $out" for (split //, $out);
	$id - $COUNT;
}

1;

__END__

=head1 NAME

Bijection - Bijection.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Bijection qw/all/;

	my $int = 1;
	my $string = biject($int);
	inverse($string) == $int;

=head1 EXPORT

=head2 biject

=cut

=head2 inverse

=cut

=head1 AUTHOR

lnation, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bijection at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bijection>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bijection


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bijection>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bijection>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bijection>

=item * Search CPAN

L<http://search.cpan.org/dist/Bijection/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 lnation.

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

1; # End of Bijection
