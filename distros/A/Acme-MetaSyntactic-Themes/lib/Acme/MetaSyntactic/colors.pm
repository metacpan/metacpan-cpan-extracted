package Acme::MetaSyntactic::colors;
use strict;
use Acme::MetaSyntactic::Alias;
our @ISA = qw( Acme::MetaSyntactic::Alias );
our $VERSION = '1.001';
__PACKAGE__->init('colours');
1;

=head1 NAME

Acme::MetaSyntactic::colors - The colors theme

=head1 DESCRIPTION
    
This theme is just an alias of the C<colours> theme, to please the
speakers of the various dialects of English. C<;-)>

=head1 CONTRIBUTOR

Philippe Bruhat

=head1 CHANGES

=over 4

=item *

2012-07-23 - v1.001

C<use strict> to make Acme-MetaSyntactic-Themes version 1.011
satisfy all required CPANTS kwalitee tests.

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2005-06-05

Introduced in Acme-MetaSyntactic version 0.77.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::Alias>,
L<Acme::MetaSyntactic::colours>.

=cut
    
# no __DATA__ section required!

