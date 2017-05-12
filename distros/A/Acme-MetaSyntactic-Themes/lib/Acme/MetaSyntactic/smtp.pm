package Acme::MetaSyntactic::smtp;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::smtp - The (E)SMTP commands theme

=head1 DESCRIPTION

Commands of the SMTP and ESMTP protocols, as described in
RFC 821 (L<http://www.ietf.org/rfc/rfc821.txt>) and
RFC 2821 (L<http://www.ietf.org/rfc/rfc2821.txt>).

=head1 CONTRIBUTOR

Abigail

=head1 CHANGES

=over 4

=item *

2012-05-07

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-03-20

Introduced in Acme-MetaSyntactic version 0.66.

=item *

2005-10-27

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
HELO EHELO MAIL RCPT DATA SEND SOML SAML RSET VRFY EXPN HELP NOOP QUIT TURN
