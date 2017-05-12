#
# Courier::Filter::Util
# Utility class for the Courier::Filter framework.
#
# (C) 2003-2008 Julian Mehnle <julian@mehnle.net>
# $Id: Util.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Util - Utility class used by the Courier::Filter framework

=cut

package Courier::Filter::Util;

use warnings;
use strict;

use base 'Exporter';

use Error ':try';

use Courier::Error;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

our @EXPORT_OK = qw(
    ipv4_address_pattern
    ipv6_address_pattern
    loopback_address_pattern
);

=head1 SYNOPSIS

    use Courier::Filter::Util qw(
        ipv4_address_pattern
        ipv6_address_pattern
        loopback_address_pattern
    );
    
    $message->remote_host =~ / ^ (?: ::ffff: )? $(\ipv4_address_pattern} $ /x;
    $message->remote_host =~ / ^ $(\ipv6_address_pattern} $ /x;
    $message->remote_host =~ / ^ ${\loopback_address_pattern} $ /x;

=head1 DESCRIPTION

B<Courier::Filter::Util> is Courier::Filter's utility class.

=cut

# Implementation:
###############################################################################

=head2 Constants

The following constants are provided:

=over

=item B<ipv4_address_pattern>

A regular expression matching an IPv4 address in "dotted decimal" notation.

=cut

use constant octet_decimal_pattern      => qr/ 0*? \d | \d\d | [01]\d\d | 2[0-4]\d | 25[0-5] /x;

use constant ipv4_address_pattern       => qr/ ${\octet_decimal_pattern} (?: \. ${\octet_decimal_pattern} ){3} /x;

=item B<ipv6_address_pattern>

A regular expression matching an IPv6 address in full RFC 4291 syntax.

=cut

use constant hexword_pattern            => qr/\p{IsXDigit}{1,4}/;
use constant two_hexwords_or_ipv4_address_pattern => qr/
    ${\hexword_pattern} : ${\hexword_pattern} | ${\ipv4_address_pattern}
/x;

use constant ipv6_address_pattern       => qr/
    #                x:x:x:x:x:x:x:x |     x:x:x:x:x:x:n.n.n.n
    (?: ${\hexword_pattern} : ){6}                                    ${\two_hexwords_or_ipv4_address_pattern} |
    #                 x::x:x:x:x:x:x |      x::x:x:x:x:n.n.n.n
    (?: ${\hexword_pattern} : ){1}   : (?: ${\hexword_pattern} : ){4} ${\two_hexwords_or_ipv4_address_pattern} |
    #               x[:x]::x:x:x:x:x |    x[:x]::x:x:x:n.n.n.n
    (?: ${\hexword_pattern} : ){1,2} : (?: ${\hexword_pattern} : ){3} ${\two_hexwords_or_ipv4_address_pattern} |
    #               x[:...]::x:x:x:x |    x[:...]::x:x:n.n.n.n
    (?: ${\hexword_pattern} : ){1,3} : (?: ${\hexword_pattern} : ){2} ${\two_hexwords_or_ipv4_address_pattern} |
    #                 x[:...]::x:x:x |      x[:...]::x:n.n.n.n
    (?: ${\hexword_pattern} : ){1,4} : (?: ${\hexword_pattern} : ){1} ${\two_hexwords_or_ipv4_address_pattern} |
    #                   x[:...]::x:x |        x[:...]::n.n.n.n
    (?: ${\hexword_pattern} : ){1,5} :                                ${\two_hexwords_or_ipv4_address_pattern} |
    #                     x[:...]::x |                       -
    (?: ${\hexword_pattern} : ){1,6} :     ${\hexword_pattern}                                                 |
    #                      x[:...]:: |                       -
    (?: ${\hexword_pattern} : ){1,7} :                                                                         |
    #                      ::[...:]x |                       -
 :: (?: ${\hexword_pattern} : ){0,6}       ${\hexword_pattern}                                                 |
    #                              - |         ::[...:]n.n.n.n
 :: (?: ${\hexword_pattern} : ){0,5}                                  ${\two_hexwords_or_ipv4_address_pattern} |
    #                             :: |                       -
 ::
/x;

=item B<loopback_address_pattern>

A regular expression matching an IPv4 or IPv6 loopback address (C<127.n.n.n>,
C<::ffff:127.n.n.n.n>, C<::1>).

=cut

use constant loopback_address_pattern   => qr/ (?: ::ffff: )? 127 (?: \.\d{1,3} ){3} | ::1 /x;

=back

=head1 SEE ALSO

L<Courier::Filter>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
