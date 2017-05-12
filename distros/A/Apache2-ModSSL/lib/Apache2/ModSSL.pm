package Apache2::ModSSL;

use strict;
use warnings FATAL => 'all';

use XSLoader ();
our $VERSION = '0.10';
XSLoader::load __PACKAGE__, $VERSION
  if( exists $ENV{MOD_PERL} and $ENV{MOD_PERL}=~/mod_perl/ );

1;

__END__

=head1 NAME

Apache2::ModSSL - a Perl Interface to mod_ssl functions

=head1 SYNOPSIS

 use Apache2::ModSSL;

 my $c=$r->connection;
 if( $c->is_https ) {
   $dn=$c->ssl_var_lookup('SSL_SERVER_S_DN');
   $nsComment=$c->ssl_ext_lookup(0, '2.16.840.1.113730.1.13');
 }

=head1 ABSTRACT

C<Apache2::ModSSL> adds a few functions that are exported from C<mod_ssl>
to the C<Apache2::Connection> class.

=head1 METHODS

=over 4

=item B<$c-E<gt>is_https>

C<is_https()> returns 1 if the connection is SSL-encrypted, 0 if it
is not encrypted but mod_ssl is available in the apache binary or
C<undef> if mod_ssl is not loaded.

=item B<$c-E<gt>ssl_var_lookup(NAME)>

C<ssl_var_lookup()> returns the value of an SSL variable. If mod_ssl
is not loaded C<undef> is returned. A query for an unknown variable
returns an empty string.

For a list of known variables please refer to the mod_ssl documentation
or mod_ssl source code (C<httpd-2.0.52/modules/ssl/ssl_engine_vars.c>).
At the time of this writing this list includes (not complete):

=over 4

=item B<HTTPS>

=item B<API_VERSION>

=item B<SSL_VERSION_PRODUCT>

=item B<SSL_VERSION_INTERFACE>

=item B<SSL_VERSION_LIBRARY>

=item B<SSL_PROTOCOL>

=item B<SSL_SESSION_ID>

=item B<SSL_CIPHER>

=item B<SSL_CLIENT_CERT_CHAIN_n> (where n is a number)

=item B<SSL_CLIENT_VERIFY>

=item B<SSL_(CLIENT|SERVER)_M_VERSION>

=item B<SSL_(CLIENT|SERVER)_M_SERIAL>

=item B<SSL_(CLIENT|SERVER)_V_START>

=item B<SSL_(CLIENT|SERVER)_V_END>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_C>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_ST>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_SP>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_L>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_O>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_OU>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_CN>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_T>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_I>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_G>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_S>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_D>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_UID>

=item B<SSL_(CLIENT|SERVER)_(S|I)_DN_Email>

=item B<SSL_(CLIENT|SERVER)_A_SIG>

=item B<SSL_(CLIENT|SERVER)_A_KEY>

=item B<SSL_(CLIENT|SERVER)_CERT>

=back

=item B<$c-E<gt>ssl_ext_lookup(WHERE, OID)>

C<ssl_ext_lookup()> returns the value of an SSL certificate extension.
C<WHERE> specifies whether to look in the WEB server certificate (C<WHERE==0>)
or in the client certificate (C<WHERE==1>). C<OID> is the Object Identifier
for the extension in dotted notation, e.g. C<2.16.840.1.11330.1.13> for
C<Netscape Comment> or C<2.5.29.19> for C<X509v3 Basic Constraints>.

=back

=head1 EXPORTS

none.

=head1 SEE ALSO

L<http://perl.apache.org/docs/2.0/api/Apache2/Connection.html>,
L<http://httpd.apache.org/docs-2.0/mod/mod_ssl.html>

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
