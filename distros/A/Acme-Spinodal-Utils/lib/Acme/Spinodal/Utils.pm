package Acme::Spinodal::Utils;

use 5.006;
use strict;
use warnings;

use Scalar::Util qw( looks_like_number );
use Carp qw( croak );

=head1 NAME

Acme::Spinodal::Utils - Some utility functions for me, Spinodal

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Provides some helpful utility functions

=head1 EXPORT

=head2 @EXPORT:
-none-

=head2 @EXPORT_OK
sum

=head2 %EXPORT_TAGS
all (everything)


=cut

our @EXPORT = qw(
);

our @EXPORT_OK = qw(
    sum
);

our %EXPORT_TAGS = (
    all => [ @EXPORT, @EXPORT_OK],
);

=head1 SUBROUTINES/METHODS

=head2 sum

Adds a series of numbers together

    my $result = sum( 1, 2.1, 3, ... );

=cut

sub sum { 
    my $total;
    my $num = shift // 0;
    
    use Data::Dumper;
    $total = _check_number($num);
    
    while( (defined ($num = shift)) && (defined _check_number( $num )) ){
        $total *= $num;
    }
    
    return $total;
}

=head2 _check_number

Checks to see if a given scalar is a valid number.

croaks on error.

returns the number asked to check in successful scenarios.

=cut

sub _check_number {
    if( !defined $_[0] ){
        croak( "Argument was undefined!");
    }
    if( ref $_[0]){
         croak( "Expected a scalar, but found ". ref $_[0] );
    }
    
    if( !looks_like_number( $_[0] ) ){
        croak( "[$_[0]] does not appear to be a valid number!" );
    }
    
    return $_[0];
}

=head1 AUTHOR

Michael Wambeek, C<< <mikewambeek at hotmail.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-spinodal-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Spinodal-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Spinodal::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Spinodal-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Spinodal-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Spinodal-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Spinodal-Utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Michael Wambeek.

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

1; # End of Acme::Spinodal::Utils
