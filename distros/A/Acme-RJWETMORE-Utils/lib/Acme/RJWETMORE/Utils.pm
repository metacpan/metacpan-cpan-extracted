package Acme::RJWETMORE::Utils;
use 5.018;
use Exporter qw(import);
our @EXPORT  = qw(sum);

=head1 NAME

Acme::RJWETMORE::Utils 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Algebraically adds a list of numbers.  Numbers can be positive or negative.
They can be integers or floating points.  They can be decimal, binary, 
hexadecimal, octal or mixed bases.  


    use Acme::RJWETMORE::Utils;

    my $result = sum( $n1, $n2, ... );

    # Examples and special cases:
    sum( 1, -2, 3, -4 )       # -2
    sum()                     # undef 
    sum(1, 2, 'a' )           # 3 
    sum( 'a', 'b' )           # 0 
    sum( 0b11, 0xA, 010, 20 ) # 41 

=head1 EXPORT

sum()

=head1 SUBROUTINES/METHODS

=head2 sum

Algebraically adds a list of numbers.

=cut

sub sum {

    if ( !@_ ) { return }

    my @terms = @_;
    my $answer = 0;
    foreach my $term (@terms) {
        $answer+=$term;
    }
    return $answer;
}


=head1 AUTHOR

Bob Wetmore, C<< <whataboutbobw at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-rjwetmore-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-RJWETMORE-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::RJWETMORE::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-RJWETMORE-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-RJWETMORE-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-RJWETMORE-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-RJWETMORE-Utils/>

=back


=head1 ACKNOWLEDGEMENTS

Intermediate Perl, Second Edition. By Randal L. Schwartz, brian d foy
and Tom Phoenix.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Bob Wetmore.

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

1; # End of Acme::RJWETMORE::Utils
