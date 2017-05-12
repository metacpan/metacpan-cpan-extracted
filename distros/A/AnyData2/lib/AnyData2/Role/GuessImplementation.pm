package AnyData2::Role::GuessImplementation;

use 5.008001;
use strict;
use warnings FATAL => 'all';

use base "Exporter";
our @EXPORT = "_guess_suitable_class";

use Carp qw/croak/;
use List::MoreUtils qw(firstval);
use Module::Runtime qw(require_module);

=head1 NAME

AnyData2::Role::GuessImplementation - provides role for guessing suitable implementation

=cut

our $VERSION = '0.002';

=head1 METHODS

=head2 _guess_suitable_class(@suitables)

Finds first suitable class from C<@suitables>. Results are cached.

=cut

my %suitable_classes;

sub _guess_suitable_class
{
    my ( $class, @classlist ) = @_;
    $suitable_classes{$class} or $suitable_classes{$class} = firstval
    {
        eval { require_module($_); }
    }
    @classlist;
    $suitable_classes{$class} or croak( "No suitable class out of (" . join( ", ", @classlist ) . ")for $class available" );
    $suitable_classes{$class};
}

=head1 LICENSE AND COPYRIGHT

Copyright 2015,2016 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

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
direct or contributory patent infringement, then this License
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

1;
