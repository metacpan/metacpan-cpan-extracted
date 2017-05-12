package CGI::Untaint::countryname;
use warnings;
use strict;
use Locale::Country();

use base 'CGI::Untaint::printable';

=over 4

=item is_valid

=back

=cut

sub is_valid {
    my ( $self ) = @_;

    # name in, name out
    return Locale::Country::country2code( $self->value ) ? 1 : undef;
}

1;