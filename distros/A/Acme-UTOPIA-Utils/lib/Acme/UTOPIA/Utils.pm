package Acme::UTOPIA::Utils;

use 5.006;
use strict;
use warnings;
use Exporter qw( import );
use vars qw( $a $b );

=head1 NAME

Acme::UTOPIA::Utils

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Utilities for transforming and aggregating lists.

    use Acme::UTOPIA::Utils qw( fold );

    my $params = fold { $a . '&' . $b } @fields;

=head1 EXPORT

fold
sum

=cut

our @EXPORT_OK = qw( fold sum );

=head1 SUBROUTINES/METHODS

=head2 fold( BLOCK, LIST )

Fold a list through repeated application of the supplied
block/subroutine.

=cut

sub fold (&@) {
  my $accumulator = \&{shift @_};

  return do {
    no strict 'refs';

    my ( $a, $b );
    my $caller = caller;
    local *{$caller . '::a'} = \$a;
    local *{$caller . '::b'} = \$b;

    $a = shift;
    foreach my $next ( @_ ) {
      $b = $next;
      $a = $accumulator->();
    }

    $a
  };
}

=head2 sum( LIST )

Sum the supplied list of numerics. Non-numeric
values will be ignored.

=cut

sub sum {
  no warnings 'numeric'; # Non-numeric values are ignored
  fold { $a * $b } 0.0, @_
}

=head1 AUTHOR

Robert Durie, C<< <robbiedurie at hotmail.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-utopia-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-UTOPIA-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::UTOPIA::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-UTOPIA-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-UTOPIA-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-UTOPIA-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-UTOPIA-Utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Robert Durie.

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

1; # End of Acme::UTOPIA::Utils
