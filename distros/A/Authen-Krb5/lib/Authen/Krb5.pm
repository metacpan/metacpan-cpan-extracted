package Authen::Krb5;
$Authen::Krb5::VERSION = '1.905';
# ABSTRACT: XS bindings for Kerberos 5

use strict;
use warnings;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);

use 5.008_008;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
	ADDRTYPE_ADDRPORT
	ADDRTYPE_CHAOS
	ADDRTYPE_DDP
	ADDRTYPE_INET
	ADDRTYPE_IPPORT
	ADDRTYPE_ISO
	ADDRTYPE_XNS
	AP_OPTS_MUTUAL_REQUIRED
	AP_OPTS_RESERVED
	AP_OPTS_USE_SESSION_KEY
	AP_OPTS_USE_SUBKEY
	AP_OPTS_WIRE_MASK
	KDC_OPT_ALLOW_POSTDATE
	KDC_OPT_ENC_TKT_IN_SKEY
	KDC_OPT_FORWARDABLE
	KDC_OPT_FORWARDED
	KDC_OPT_POSTDATED
	KDC_OPT_PROXIABLE
	KDC_OPT_PROXY
	KDC_OPT_RENEW
	KDC_OPT_RENEWABLE
	KDC_OPT_RENEWABLE_OK
	KDC_OPT_VALIDATE
	KRB5_AUTH_CONTEXT_DO_SEQUENCE
	KRB5_AUTH_CONTEXT_DO_TIME
	KRB5_AUTH_CONTEXT_GENERATE_LOCAL_ADDR
	KRB5_AUTH_CONTEXT_GENERATE_LOCAL_FULL_ADDR
	KRB5_AUTH_CONTEXT_GENERATE_REMOTE_ADDR
	KRB5_AUTH_CONTEXT_GENERATE_REMOTE_FULL_ADDR
	KRB5_AUTH_CONTEXT_RET_SEQUENCE
	KRB5_AUTH_CONTEXT_RET_TIME
	KRB5_NT_PRINCIPAL
	KRB5_NT_SRV_HST
	KRB5_NT_SRV_INST
	KRB5_NT_SRV_XHST
	KRB5_NT_UID
	KRB5_NT_UNKNOWN
	KRB5_TGS_NAME
);

sub KRB5_TGS_NAME() { return "krbtgt"; }

bootstrap Authen::Krb5 $Authen::Krb5::VERSION;

# Preloaded methods go here.

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Krb5 macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Authen::Krb5 - XS bindings for Kerberos 5

=head1 VERSION

version 1.905

=head1 SYNOPSIS

  use Authen::Krb5;
  Authen::Krb5::init_context();

=head1 DESCRIPTION

C<Authen::Krb5> is an object oriented interface to the Kerberos 5 API.  Both the
implementation and documentation are nowhere near complete, and may require
previous experience with Kerberos 5 programming.  Most of the functions here
are documented in detail in the
L<Kerberos 5 API documentation|http://web.mit.edu/kerberos/krb5-current/doc/appdev/refs/api/index.html>

=head1 FUNCTIONS

=head2 C<error(n)>

Returns the error code from the most recent C<Authen::Krb5> call.  If provided
with an error code C<n>, this function will return a textual description of the
error.

=head2 C<init_context()>

Initializes a context for the application. Returns a C<Authen::Krb5::Context>
object, or C<undef> if there was an error.

=head2 C<init_ets() (DEPRECATED)>

Initializes the Kerberos error tables.  Should be called along with
L</init_context()> at the beginning of a script.

=head2 C<get_default_realm()>

Returns the default realm of your host.

=head2 C<get_host_realm(host)>

Returns the realm of the specified host.

=head2 C<get_krbhst(realm)>

Returns a list of the Kerberos servers from the specified realm.

=head2 C<build_principal_ext(p)>

Not like the actual C<krb5_build_principal_ext>.  This is legacy code from
Malcolm's code, which I'll probably change in future releases.  In any case,
it creates a 'server' principal for use in getting a TGT.  Pass it the
principal for which you would like a TGT.

=head2 C<parse_name(name)>

Converts a string representation of a principal to a principal object.  You
can use this to create a principal from your username.

=head2 C<sname_to_principal(hostname,sname,type)>

Generates a server principal from the given hostname, service, and type.
Type can be one of the following: NT_UNKNOWN, NT_PRINCIPAL, NT_SRV_INST,
NT_SRV_HST, NT_SRV_XHST, NT_UID.  See the Kerberos documentation for details.

=head2 C<cc_resolve(name)>

Returns a credentials cache identifier which corresponds to the given name.
'name' must be in the form TYPE:RESIDUAL.  See the Kerberos documentation
for more information.

=head2 C<cc_default_name()>

Returns the name of the default credentials cache, which may be equivalent
to KRB5CCACHE.

=head2 C<cc_default()>

Returns a L<Authen::Krb5::Ccache> object representing the default credentials
cache.

=head2 C<kt_resolve(name)>

Returns a L<Authen::Krb5::Keytab> object representing the specified keytab name.

=head2 C<kt_default_name()>

Returns a sting containing the default keytab name.

=head2 C<kt_default()>

Returns an L<Authen::Krb5::Keytab> object representing the default keytab.

=head2 C<kt_read_service_key(name, principal[, kvno, enctype])>

Searches the keytab specified by I<name> (the default keytab if
I<name> is undef) for a key matching I<principal> (and optionally
I<kvno> and I<enctype>) and returns the key in the form of an
L<Authen::Krb5::Keyblock> object.

=head2 C<get_init_creds_password(client, password[, service])>

Attempt to get an initial ticket for the client.  'client' is a principal
object for which you want an initial ticket.  'password' is the password for
the client.  'service', if given, is the string representation (not a
principal object) for the ticket to acquire.  If not given, it defaults to
C<krbtgt/REALM@REALM> for the local realm.  Returns an L<Authen::Krb5::Creds>
object or undef on failure.

=head2 C<get_init_creds_keytab(client, keytab[, service])>

Attempt to get an inintial ticket for the client using a keytab.  'client'
is a principal object for which you want an initial ticket.  'keytab' is a
keytab object created with kt_resolve.  'service', if given, is the string
representation (not a principal object) for the ticket to acquire.  If not
given, it defaults to C<krbtgt/REALM@REALM> for the local realm.  Returns an
L<Authen::Krb5::Creds> object or undef on failure.

=head2 C<get_in_tkt_with_password(client,server,password,cc)>

Attempt to get an initial ticket for the client.  'client' is a principal
object for which you want an initial ticket.  'server' is a principal object
for the service (usually C<krbtgt/REALM@REALM>).  'password' is the password
for the client, and 'cc' is a L<Authen::Krb5::Ccache> object representing the
current credentials cache.  Returns a Kerberos error code.

Although this interface is deprecated in the Kerberos C libraries, it's
supported in the Perl module.  In this module, it's implemented in terms of
C<krb5_get_init_creds_password>, L<krb5_cc_initialize>, and L<krb5_cc_store_cred>.

=head2 C<get_in_tkt_with_keytab(client,server,keytab,cc)>

Obtain an initial ticket for the client using a keytab.  'client' is a
principal object for which you want an initial ticket.  'server' is a
principal object for the service (usually C<krbtgt/REALM@REALM>).  'keytab' is
a keytab object createed with kt_resolve.  'cc' is a L<Authen::Krb5::Ccache>
object representing the current credentials cache.  Returns a Kerberos error
code.

Although this interface is deprecated in the Kerberos C libraries, it's
supported in the Perl module.  In this module, it's implemented in terms of
L<krb5_get_init_creds_keytab>, L<krb5_cc_initialize>, and L<krb5_cc_store_cred>.

=head2 C<mk_req(auth_context,ap_req_options,service,hostname,in,cc)>

Obtains a ticket for a specified service and returns a C<KRB_AP_REQ> message
suitable for passing to rd_req.  'auth_context' is the L<Authen::Krb5::AuthContext>
object you want to use for this connection, 'ap_req_options' is an OR'ed
representation of the possible options (see Kerberos docs), 'service' is
the name of the service for which you want a ticket (like 'host'), hostname
is the hostname of the server, 'in' can be any user-specified data that can
be verified at the server end, and 'cc' is your credentials cache object.

=head2 C<rd_req(auth_context,in,server,keytab)>

Parses a C<KRB_AP_REQ> message and returns its contents in a L<Authen::Krb5::Ticket>
object.  'auth_context' is the connection's L<Authen::Krb5::AuthContext> object,
'in' is the C<KRB_AP_REQ> message (usually from mk_req), and server is the
expected server's name for the ticket.  'keytab' is a L<Authen::Krb5::Keytab>
object for the keytab you want to use.  Specify C<undef> or leave off to use
the default keytab.

=head2 C<mk_priv(auth_context,in)>

Encrypts 'in' using parameters specified in auth_context, and returns the
encrypted data.  Requires use of a replay cache.

=head2 C<rd_priv(auth_context,in)>

Decrypts 'in' using parameters specified in auth_context, and returns the
decrypted data.

=head2 C<sendauth(auth_context,fh,version,client,server,options,in,in_creds,cc)>

Obtains and sends an authenticated ticket from a client program to a server
program using the filehandle 'fh'.  'version' is an application-defined
version string that recvauth compares to its own version string.  'client'
is the client principal, e.g. C<username@REALM>.  'server' is the service
principal to which you are authenticating, e.g. C<service.hostname@REALM>.
The only useful option right now is C<AP_OPTS_MUTUAL_REQUIRED>, which forces
sendauth to perform mutual authentication with the server.  'in' is a string
that will be received by recvauth and verified by the server--it's up to the
application.  'in_creds' is not yet supported, so just use 'undef' here.  'cc'
should be set to the current credentials cache.  sendauth returns true
on success and undefined on failure.

=head2 C<recvauth(auth_context,fh,version,server,keytab)>

Receives authentication data from a client using the sendauth function through
the filehandle 'fh'.  'version' is as described in the sendauth section.
'server' is the server principal to which the client will be authenticating.
'keytab' is a C<Authen::Krb5::Keytab> object specifying the keytab to use for this
service.  recvauth returns a C<Authen::Krb5::Ticket> object on success or
undefined on failure.

=head2 C<genaddrs(auth_context,fh,flags)>

Uses the open socket filehandle 'fh' to generate local and remote addresses
for auth_context.  Flags should be one of the following, depending on the
type of address you want to generate (flags can be OR'ed):

  KRB5_AUTH_CONTEXT_GENERATE_LOCAL_ADDR
  KRB5_AUTH_CONTEXT_GENERATE_LOCAL_FULL_ADDR
  KRB5_AUTH_CONTEXT_GENERATE_REMOTE_ADDR
  KRB5_AUTH_CONTEXT_GENERATE_REMOTE_FULL_ADDR

=head2 C<gen_portaddr(addr,port)>

Generates a local port address that can be used to name a replay cache.  'addr' is a L<Authen::Krb5::Address> object, and port is a port number in network byte
order.  For generateing a replay cache name, you should supply the local
address of the client and the socket's local port number.  Returns a
Authen::Krb5::Address object containing the address.

=head2 C<gen_replay_name(addr,string)>

Generate a unique replay cache name.  'addr' is a L<Authen::Krb5::Address> object
created by gen_portaddr.  'string' is used as a unique identifier for the
replay cache.  Returns the replay cache name.

=head2 C<get_server_rcache(name)>

Returns a L<Authen::Krb5::Rcache> object using the replay cache name 'name.'

=for Pod::Coverage KRB5_TGS_NAME constant free_context

=head1 ACKNOWLEDGEMENTS

Based on the original work by Doug MacEachern and Malcolm Beattie.  Code
contributions from Scott Hutton (shutton@indiana.edu).

=head1 SEE ALSO

perl(1), kerberos(1).

=head1 AUTHOR

Jeff Horwitz <jeff@smashing.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Jeff Horwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
