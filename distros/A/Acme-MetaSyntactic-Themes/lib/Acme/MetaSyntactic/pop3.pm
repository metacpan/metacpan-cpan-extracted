package Acme::MetaSyntactic::pop3;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::pop3 - The pop3 theme

=head1 DESCRIPTION

This theme list all the POP3 commands, responses and states,
as listed in RFC 1939.

See L<http://www.ietf.org/rfc/rfc1939.txt> for details regarding
the POP3 protocol.

The history of the POP3 RFC is as follows:
RFC 1939 obsoletes
RFC 1725, which obsoletes
RFC 1460, which obsoletes
RFC 1225, which obsoletes
RFC 1081.

=head1 CONTRIBUTOR

Philippe "BooK" Bruhat

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-03-27

Introduced in Acme-MetaSyntactic version 0.67.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
USER PASS QUIT STAT LIST RETR DELE NOOP RSET
APOP TOP UIDL
OK ERR
AUTHORIZATION TRANSACTION
