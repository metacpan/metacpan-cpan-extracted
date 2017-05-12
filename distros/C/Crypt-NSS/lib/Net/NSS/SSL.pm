package Net::NSS::SSL;

use strict;
use warnings;

use Carp qw(croak);
use Socket;

use Crypt::NSS::Constants qw(:ssl);

use Net::NSS::SSL::LWPCompat;

my %socket_type = ( 
    tcp  => SOCK_STREAM,
	udp  => SOCK_DGRAM,
	icmp => SOCK_RAW,
);

# What client cert hook to use if not specified
our $DefaultClientCertHook;

# What argument to send to the client cert hook if not specified
our $DefaultClientCertHookArg;

# What URL to set on the socket that the verification should be against if not specified.
our $DefaultURL;

# The callback to use for verifing certs
our $DefaultVerifyCertHook;

sub new {
    my $pkg = shift;
    my %args = @_ & 1 ? do { my $addr = shift; (@_, PeerAddr => $addr); } : @_;
    
    my $proto = "tcp";
    my $type = defined $args{Type} ? $args{Type} : SOCK_STREAM;

    # Convert (Peer|Local)Addr to ${1}Host + ${1}Port unless specified and convert named port
    for my $pre (qw(Peer Local)) {
        if ($args{"${pre}Addr"}) {
            ($args{"${pre}Port"}) = $args{"${pre}Addr"} =~ /:(\w+)$/ if !defined $args{"${pre}Port"};
            $args{"${pre}Host"} = $args{"${pre}Addr"};
            $args{"${pre}Host"} =~ s/:.*$//;
        }
        
        # Non-numerical port, look up from /etc/services or equivalent
        if (exists $args{"${pre}Port"} && $args{"${pre}Port"} !~ /^\d+$/) {
            my @serv = getservbyname($args{"${pre}Port"}, "tcp");
            croak "Can't get port for protocol '", $args{"${pre}Port"}, "'" unless @serv;
            $args{"${pre}Port"} = $serv[2];
        }
    }
    # Blocking is a bit special. We should consult a callback for this unless it's specified
    if (!exists $args{Blocking} && $pkg->can("blocking")) {
        $args{Blocking} = $pkg->blocking;
    }

    $args{Blocking} = 1 unless defined $args{Blocking};
    
    # Always create tcp sockets right now
    my $sock = Net::NSS::SSL->create_socket("tcp");
    
    $sock->set_option(Blocking => $args{Blocking});

    # Optional options
    for my $option (qw(KeepAlive ReuseAddr)) {
        next unless exists $args{$option} && defined $args{$option};
        $sock->set_option($option, ($args{$option} ? 1 : 0));
    }

    # Upgrade to SSL socket
    $sock->import_into_ssl_layer();

    if (!exists $args{SSL_PKCS11_PinArg}) {
        $sock->set_pkcs11_pin_arg($Crypt::NSS::PKCS11::DefaultPinArg);
    }
    
    # Client certificates, only for client sockets
    if ($args{PeerHost} && $args{PeerPort}) {
        my @client_cert_arg = exists $args{SSL_ClientCertHookArg} ? $args{SSL_ClientCertHookArg} : 
                              defined $DefaultClientCertHookArg ? $DefaultClientCertHookArg :
                              ();
                              
        if (!exists $args{SSL_ClientCertHook}) {
            if ($DefaultClientCertHook) {
                $sock->set_client_certificate_hook($DefaultClientCertHook, @client_cert_arg);
            }
        }
        else {
            $sock->set_client_certificate_hook($args{SSL_ClientCertHook}, @client_cert_arg);
        }
    }

    # Verification callback
    if ($args{SSL_VerifyCertHook}) {
        $sock->set_verify_certificate_hook($args{SSL_VerifyCertHook});
    }
    elsif ($DefaultVerifyCertHook) {
        $sock->set_verify_certificate_hook($DefaultVerifyCertHook);
    }
    
    # SSL Options
    my @options;
    push @options, map { [$_ => SSL_OPTION_ENABLED] } @{$args{SSL_EnableOptions}} if ref $args{SSL_EnableOptions} eq "ARRAY";
    push @options, map { [$_ => SSL_OPTION_DISABLED] } @{$args{SSL_DisableOptions}} if ref $args{SSL_DisableOptions} eq "ARRAY";
    for my $opt (@options) {
        my ($opt_name, $on) = @$opt;
        eval {
            $opt_name = Crypt::NSS::Constants->$opt_name();
        };
        croak "Unkown option '$opt_name'" if $@;
        $sock->set_option($opt_name, $on);
    }

    # Maybe connect
    if ($args{PeerHost} && $args{PeerPort} && !(exists $args{Connect} && !$args{Connect})) {
        if ($args{SSL_URL}) {
            $sock->set_URL($args{SSL_URL});
        }
        elsif ($DefaultURL) {
            $sock->set_URL($DefaultURL);
        }
        else {            
            $sock->set_URL($args{PeerHost});
        }
        
        $sock->connect($args{PeerHost}, $args{PeerPort}, ($args{Timeout} ? $args{Timeout} : ()));
    }

    return $sock;
}

sub peerhost {
    my ($host, undef) = shift->_peeraddr;
    return $host;
}

sub peerport {
    my (undef, $port) = shift->_peeraddr;
    return $port;
}

sub sockhost {
    my ($host, undef) = shift->_sockaddr;
    return $host;
}

sub sockport {
    my (undef, $port) = shift->_sockaddr;
    return $port;
}

# Alias needed for LWP among other things
*get_peer_certificate   = \&peer_certificate;
*get_cipher             = \&cipher;
*get_keysize            = \&keysize;
*get_secret_keysize     = \&secret_keysize;
*get_issuer             = \&issuer;
*get_cipher             = \&cipher;

*syswrite = \&write;
*sysread = \&read;

1;
__END__

=head1 NAME

Net::NSS::SSL - SSL sockets using NSS

=head1 SYNOPSIS

=head1 INTERFACE

=head2 CLASS METHODS

=head3 Creating sockets

The prefered way of creating sockets is by using the C<new> constructor. This creates this socket, 
sets the desired options, imports it into SSL layer and connects to the peer host, or binds and sets up 
a listening socket, in the correct order. If you need more control it's possible to create a new socket 
using C<create_socket> which in turn must be SSL enabled by calling C<import_into_ssl_layer> before 
connecting or listening.

=over 4

=item new ( $address : string, %args ) : Net::NSS::SSL

=item new ( %args ) : Net::NSS::SSL

Creates a new socket, sets it up correctly, imports it into NSS SSL layer and optionally if it's a 
client-side socket connect to the remote host.

=over 4

=item PeerAddr : string

The peer to connect to in form of C<<host>>, C<<host>:<port>> or C<<host>:<service>> where host is either an IP number or a hostname, port 
a integer in the range 1-65535. If a service is specified such as C<http> or C<ftp>, its port number is looked up using C<getservbyname> with 
the proto C<tcp>.

=item PeerPort : string | integer

The numerical port or a service name to connect to. If I<PeerAddr> is specified it may take precedence over this. 

=item PeerHost : string

The host to connect to as either an IP number or a hostname. If I<PeerAddr> is specified is may take precedence over this.

=item Connect : boolean

If true then create the socket, import it into SSL, set the specfied options but don't connect. Defaults to false if omitted.

=item KeepAlive : boolean

Periodically test whether connection is still alive. Default to false if omitted.

=item Blocking : boolean

Blocking or non-blocking I/O. Default to 1 if omitted or what the class method C<blocking> returns if such exists.

=item SSL_PKCS11_PinArg : scalar

Sets the PKCS11 pin arg that is sent along to various funcions for the socket. 

See also: L<Net::NSS::SSL/set_pkcs11_pin_arg>

=item SSL_ClientCertHook : coderef | string

Sets the client certificte hook for the socket. If ommited defaults I<$DefaultClientCertHook> if one is defined.

See also: L<Net::NSS::SSL/set_client_certificate_hook>. 

=item SSL_ClientCertHookArg : scalar

Sets the client certificate hook argument for the socket. If ommited defaults to I<$DefaultClientCertHookArg> if defined.

=item SSL_CertVerifyHook : coderef | string

Sets the hook that is called to verify the certificate. If ommited defaults to I<$DefaultVerifyCertHook> if one is defined.

See also: L<Net::NSS::SSL/set_verify_certificate_hook>.

=item SSL_EnableOptions : arrayref

A list of options to enable where the items are either numeric or a constant name from C<Crypt::NSS::SSL::Constants>.

=item SSL_DisableOptions : arrayref

A list of options to enable where the items are either numeric or a constant name from C<Crypt::NSS::SSL::Constants>.

=item SSL_URL : string

Sets the host/URL that the server certificate will be verified against. If ommited defaults to I<$DefaultURL> if defined, 
otherwise uses I<PeerHost>.

=back

=item create_socket ( $type : string ) : Net::NSS::SSL

Creates a new socket of the I<TYPE> C<tcp> or C<udp>. Does not set any socket options nor imports it into 
the SSL layer. You probablly want to use C<new> instead of this method.

=item import_into_ssl_layer ( )

Imports the socket into NSS SSL layer if not already done. The constructor C<new> does this automatically for 
you.

=back

=head2 INSTANCE METHODS

=head3 Connecting to a host

This is done for you if you use C<new>.

=over 4

=item connect ( $host : string, $port : integer )

=item connect ( $host : string, $port : integer, $timeout : integer)

Conencts to the host, I<$host>, on the given I<$port>. The optional argument I<$timeout> sets how many seconds 
connect has to complete the connection setup. If ommited C<PR_INTERVAL_NO_TIMEOUT> is used.

=back

=head3 Listening and accepting incoming connections

You don't need to bind and listen if you use C<new> to create your socket.

=over 4

=item bind ( $host : string, $port : integer ) 

Binds an the socket to a network address, ie host + port.

=item listen ( )
=item listen ( $queue_length : integer ) 

Listens for connections on the socket. The optional argument I<$queue_length> is the maximum length of the queue of 
pending connections. Defaults to 10.

=item configure_as_server ( $certificate : Crypt::NSS::Certificate, $private_key : Crypt::NSS::PrivateKey )

Configures a listening socket with the information needed to handshake as a SSL server. 

=item accept ( ) : Net::NSS::SSL
=item accept ( $timeout : integer ) : Net::NSS::SSL

Accepts a connection on the socket and returns the new socket used to communicate with the connected client. The 
optional argument I<$timeout> specified determined how long the connection setup might take. If ommited C<PR_INTERVAL_NO_TIMEOUT> is used.

This method blocks the calling thread until either a new connection is successfully accepted or an error occurs. 

=back

=head3 Handshaking

=over 4

=item reset_handshake ( $as_server : boolean )

Tells the the SSL library to start over with the handshake at the next I/O operation. This is not necessary for sockets 
that are already SSL:ed. The argument I<$as_server> tells whether the socket should handshake as server or client.

=back

=head3 Socket settings and security options

=over 4

=item set_option ( $option : string | integer, $value : scalar )

=item get_option ( $option : string | integer ) : scalar

Gets and sets socket options. The following options are valid:

=over 4

=item KeepAlive : boolean

Periodically test whether connection is still alive.

=item NoDelay : boolean

Disable Nagle algorithm. Don't delay send to coalesce packets.

=item Blocking : boolean

Do blocking or non-blocking (network) I/O.

=back

This method also works with SSL options if passed a numeric argument as exported by C<Crypt::NSS::Constants qw(:ssl)> and 
passing either C<SSL_OPTION_ENABLED> or C<SSL_OPTION_DISABLED> as the value.

=item set_pkcs11_pin_arg ( $arg : scalar  )

=item get_pkcs11_pin_arg ( ) : scalar

Sets or gets the argument that is passed along to pkcs11 callbacks for the given socket. I<$arg> can be any Perl scalar 
but in most cases you'll just want this to be a string. 

The default password callback (L<Crypt::NSS::PKCS11/set_password_hook>), returns this value.

=item set_URL ( $host : string )

=item get_URL ( ) : string

Set or get the domain name of the host we connect to (or actually what the CN in the servers certificate says). This 
is used in handshaking and if not matching the handshake will fail.

=item set_verify_certificate_hook ( $hook : coderef | string )

Sets a custom hook to verify an incoming certificate. The hook is passed the C<Net::NSS::SSL>-object that the 
hook is registered on, a boolean indicating whether signature should be checked and a boolean indicating if 
the certificate should be verified as a server (if true) or as a client (if false). The hook can obtain the 
certificate to be verified by calling C<peer_certificate> on the passed C<Net::NSS::SSL>-object.

To indicate that verification was ok the hook must return C<SEC_SUCCESS>, or C<SEC_FAILURE> if not. Both constants 
are exported by requesting the tag C<:sec> from C<Crypt::NSS::Constants>.

If not set, NSS uses a default hook that does the right thing in most cases. If you've replaced this with 
your own reverting to the built-in can be done by passing C<undef> to this method.

Example:

  sub my_verify_certificate_hook {
      my ($self, $check_signature, $is_server) = @_;
      
      my $cert = $self->peer_certificate():
      
      return SEC_SUCCESS;
  }

If you pass C<built-in-ignore> as the name we use a hook that never verifies the cert.

=item set_bad_certificate_hook ( $hook : coderef | string )

Sets a custom hook that is called when certficate authentication (the callback specified above) fails. 

=item set_client_certificate_hook ( $hook : coderef | string )

=item set_client_certificate_hook ( $hook : coderef | string, $arg : scalar )

Sets a custom hook that is called when a server requests a certificate for authentication. The hook is passed 
the C<Net::NSS::SSL>-object that is the subject of the authentication request and an array reference containing 
the names of the CAs the server accepts and optionally the nickname (or data) specified. The hook must return 
a 2-element list containing: 1) A C<Crypt::NSS::Certificate>-object representing the authentication certificate 
and 2) a C<Crypt::NSS::PrivateKey>-object representing the certificates private key.

By default no hook is set and one must be provided if your client application is to support client authentication. 

NSS provides a built-in hook that should be sufficient in most cases - if I<$arg> is set to a string it uses that 
as a nickname find the right cert and key otherwise it scans the database for a match. To use the built-in hook 
pass C<"built-in"> as the hook argument.

If you're using C<new> to construct the socket you can declare your callback using the key C<ClientAuthHook>.

=back

=head3 Getting security info

=over 4

=item peer_certificate ( ) : Crypt::NSS::Certificate

=item get_peer_certificate ( ) : Crypt::NSS::Certificate;

Returns the certificate recived from the remote end of the connection. If we're a client that means we 
get the servers certificate and if we're the server we get the clients authentication certificate (if used).

=item keysize () : integer

=item get_keysize () : integer

Returns the length (in bits) of the key used in the session.

=item secret_keysize ( ) : integer

=item get_secret_keysize ( ) : integer

Returns the length (in bits) of the secret part in the key used in the session. Also known as effective key size.

=item issuer ( ) : string

=item get_issuer ( ) : string

Returns the distinguished name of issuer for the certificate on the other side. Returns C<no certificate> if no certificate is used.

=item cipher ( ) : string

=item get_cipher ( ) : string

Returns the name of the cipher used in the session.

=item subject ( ) : string

=item get_subject ( ) : string

Returns the distinguished name of the certificate on the other side.

=back

=head3 Getting socket info

=over 4

=item available ( ) : integer

Returns the number of bytes of B<undecrypted> data available for read. This might not be the same amount 
when read.

=item peerhost ( ) : string

Returns the host of the remote side.

=item peerport ( ) : integer

Returns the port on the remote side.

=item sockhost ( ) : string

Returns the host on the local side.

=item sockport ( ) : integer

Returns the port on the local side.

=item is_connected ( ) : boolean

Returns true if the socket is connected to a peer or false if it's not.

=item does_ssl ( ) : boolean

Returns true if the sockets has been imported into the SSL layer or false if it has not.

=back

=head3 Reading and writing

=over 4

=item read ( $target : scalar ) : integer

=item read ( $target : scalar, $length : integer ) : integer

=item read ( $target : scalar, $length : integer, $offset : integer ) : integer

=item sysread ( $target : scalar ) : integer

=item sysread ( $target : scalar, $length : integer ) : integer

=item sysread ( $target : scalar, $length : integer, $offset : integer ) : integer

Reads data the scalar passed as I<$target> 8192 bytes at the time or I<$length>. Returns 
the actual number of bytes read or 0 if we've reached EOF. 

If I<$offset> is specified the data will not be placed at the beginning of I<$target> but at the
specified offset.

This method is blocking.

=item write ( $data : string ) : integer

=item write ( $data : string, $length : integer ) : integer

=item write ( $data : string, $length : integer, $offset : integer ) : integer

=item syswrite ( $data : string ) : integer

=item syswrite ( $data : string, $length : integer ) : integer

=item syswrite ( $data : string, $length : integer, $offset : integer ) : integer

Writes the contents of I<$data> to the socket and returns the number of bytes actually written.

=back

=head3 Finishing up

=over 4

=item close ( )

Closes the socket.

=item remove_from_session_cache ( ) 

Removes the SSL session from the cache. Communication can continue on the current socket but no new 
connections can resume the SSL session.

=back

=cut
