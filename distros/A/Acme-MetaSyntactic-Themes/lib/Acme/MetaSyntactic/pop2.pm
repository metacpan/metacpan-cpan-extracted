package Acme::MetaSyntactic::pop2;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::pop2 - The pop2 theme

=head1 DESCRIPTION

This theme list all the POP2 commands, responses and states,
as listed in RFC 937.

See L<http://www.ietf.org/rfc/rfc937.txt> for details regarding
the POP2 protocol.

The history of the POP2 RFC is as follows: RFC 937 obsoletes RFC 918.
This is a much shorter history than POP3's.

=head1 CONTRIBUTOR

Philippe "BooK" Bruhat.

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-04-03

Introduced in Acme-MetaSyntactic version 0.68.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
HELO FOLD READ RETR ACKS ACKD NACK QUIT
OK Error
CALL NMBR SIZE XFER EXIT 
LSTN AUTH MBOX ITEM NEXT DONE
