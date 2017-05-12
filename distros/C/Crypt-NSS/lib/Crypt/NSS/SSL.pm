package Crypt::NSS::SSL;

use strict;
use warnings;

1;
__END__

=head1 NAME

Crypt::NSS::SSL - Generic SSL functions from NSS

=head1 DESCRIPTION

This package provides non-socket specific SSL functions from NSS such as 
setting cipher suites, default options etc.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item set_option ( $option : integer, $value : integer )

=item get_option ( $option : integer ) : integer

Get or set defaults for SSL options on new sockets. Option should be one of the the following constants from 
C<NSS::SSL::Constants>.

=over 4

=item SSL_SECURITY

Enable or disable SSL security. If disabled the socket will not be an SSL session and thus not support encryption, 
certificates etc.

=item SSL_REQUEST_CERTIFICATE

Request the connected client to authenticate itself using client-side certificates. B<Server option only.>

=item SSL_REQUIRE_CERTIFICATE

Require the connected client to authenticate itself using client-side certificates. Requires I<SSL_REQUEST_CERTIFICATE>. 
B<Server option only.>

=item SSL_HANDSHAKE_AS_CLIENT

Controls how C<accept> on a listening socket should perform the SSL handshake. If false handshakes as server, otherwise handshakes as 
client even tho it's a server socket. B<Server option only.>

=item SSL_HANDSHAKE_AS_SERVER

Controls how C<connect> on a socket should perform the SSL handshake. If false handshakes as a client, otherwise handshakes 
client as a server. B<Client option only>.

=item SSL_ENABLE_FDX

Tell NSS that application will use full-duplex on socket, ie do writes and reads simultaneously.

=item SSL_ENABLE_SSL3

Enables or disables the SSL v3 protocol which is on by default.

=item SSL_ENABLE_SSL2

Enables or disables the SSL v2 protocol which is off by default. 

=item SSL_ENABLE_TLS

Enables or disables the TLS protocol.

=item SSL_V2_COMPATIBLE_HELLO

Tells wether to send v3 hello messages in a v2 compatible form or not. Default is on.

=item SSL_NO_CACHE

Disable the use of the session cache for sockets. If off a socket cannot resume the session started by another socket 
and thus must do the handshaking again. Default is off.

=item SSL_ROLLBACK_DETECTION

Enable or disable rollback attack detaction. Some older clients might not be able to connect if this is off.

=back

=item set_cipher ( $cipher : integer, $enabled : boolean )

=item get_cipher ( $cipher ) : boolean

Get or set whether a cipher is enabled or not.

=item config_server_session_cache ( \%ARGS )

Configure the session cache if we're are a server. The option I<ARGS> must be a hash reference and takes the following options:

=over 4

=item max_cache_entries : integer

The maximum number of entries in the cache. If ommited or specified as 0 the default 10,000 is used.

=item ssl2_timeout : integer

The lifetime of an SSL2 session. Minimum is 5 seconds, maximum is 24 hours. Default is 100 seconds.

=item ssl3_timeout : integer

The lifetime of an SSL3 session. Minimum is 5 seconds, maximum is 24 hours. Default is 24 hours.

=item data_dir : string 

The path to where to store the session cache. If omitted your systems temp dir is used.

=item shared : boolean

If your server is multithreaded or multiprocess (ie forks) you must specify this using this passing a true value in this option.

=back

=item clear_session_cache ( ) 

Clear the session cache.

=item set_cipher_suite ( suite : string )

Regulates what cipher suite we want. By default all ciphers are disabled so you must call this before any cryptographic 
functions in NSS can work. Passing C<cipher_suite> during Crypto::NSS import also does this. Currently there are three 
suites declared:

=over 4

=item C<US> (or C<Domestic>)

=item C<France>

=item C<International> (or C<Export>)

=back

=back
 
=cut