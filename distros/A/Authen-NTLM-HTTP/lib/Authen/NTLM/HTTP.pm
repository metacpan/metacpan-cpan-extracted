# -*- perl -*-
# NTLM.pm - An implementation of NTLM. In this version, I only
# implemented the client side functions that calculates the NTLM response.
# I will add the corresponding server side functions in the next version.
#

package Authen::NTLM::HTTP;

use strict;
use POSIX;
use Carp;
use MIME::Base64;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

*import = \&Exporter::import;

use base qw/Authen::NTLM::HTTP::Base/;
@EXPORT = qw ();
@EXPORT_OK = qw ();
$VERSION = '0.33';

# Stolen from Crypt::DES.
sub usage {
    my ($package, $filename, $line, $subr) = caller (1);
    $Carp::CarpLevel = 2;
    croak "Usage: $subr (@_)";
}

# Flags to indicate whether we are talking to web server or proxy
use constant NTLMSSP_HTTP_WWW => "WWW";
use constant NTLMSSP_HTTP_PROXY => "Proxy";

# These constants are stolen from samba-2.2.4 and other sources
use constant NTLMSSP_SIGNATURE => 'NTLMSSP';

# NTLMSSP Message Types
use constant NTLMSSP_NEGOTIATE => 1;
use constant NTLMSSP_CHALLENGE => 2;
use constant NTLMSSP_AUTH      => 3;
use constant NTLMSSP_UNKNOWN   => 4;

# NTLMSSP Flags

# Text strings are in unicode
use constant NTLMSSP_NEGOTIATE_UNICODE                  => 0x00000001;
# Text strings are in OEM
use constant NTLMSSP_NEGOTIATE_OEM                      => 0x00000002;
# Server should return its authentication realm
use constant NTLMSSP_REQUEST_TARGET                     => 0x00000004;
# Request signature capability
use constant NTLMSSP_NEGOTIATE_SIGN                     => 0x00000010;
# Request confidentiality
use constant NTLMSSP_NEGOTIATE_SEAL                     => 0x00000020;
# Use datagram style authentication
use constant NTLMSSP_NEGOTIATE_DATAGRAM                 => 0x00000040;
# Use LM session key for sign/seal
use constant NTLMSSP_NEGOTIATE_LM_KEY                   => 0x00000080;
# NetWare authentication
use constant NTLMSSP_NEGOTIATE_NETWARE                  => 0x00000100;
# NTLM authentication
use constant NTLMSSP_NEGOTIATE_NTLM                     => 0x00000200;
# Domain Name supplied on negotiate
use constant NTLMSSP_NEGOTIATE_OEM_DOMAIN_SUPPLIED      => 0x00001000;
# Workstation Name supplied on negotiate
use constant NTLMSSP_NEGOTIATE_OEM_WORKSTATION_SUPPLIED => 0x00002000;
# Indicates client/server are same machine
use constant NTLMSSP_NEGOTIATE_LOCAL_CALL               => 0x00004000;
# Sign for all security levels
use constant NTLMSSP_NEGOTIATE_ALWAYS_SIGN              => 0x00008000;
# TargetName is a domain name
use constant NTLMSSP_TARGET_TYPE_DOMAIN                 => 0x00010000;
# TargetName is a server name
use constant NTLMSSP_TARGET_TYPE_SERVER                 => 0x00020000;
# TargetName is a share name
use constant NTLMSSP_TARGET_TYPE_SHARE                  => 0x00040000;
# TargetName is a share name
use constant NTLMSSP_NEGOTIATE_NTLM2                    => 0x00080000;
# get back session keys
use constant NTLMSSP_REQUEST_INIT_RESPONSE              => 0x00100000;
# get back session key, LUID
use constant NTLMSSP_REQUEST_ACCEPT_RESPONSE            => 0x00200000;
# request non-ntsession key
use constant NTLMSSP_REQUEST_NON_NT_SESSION_KEY         => 0x00400000;
use constant NTLMSSP_NEGOTIATE_TARGET_INFO              => 0x00800000;
use constant NTLMSSP_NEGOTIATE_128                      => 0x20000000;
use constant NTLMSSP_NEGOTIATE_KEY_EXCH                 => 0x40000000;
use constant NTLMSSP_NEGOTIATE_80000000                 => 0x80000000;

#########################################################################
# Constructor to initialize authentication related information. In this #
# version, we assume NTLM as the authentication scheme of choice.       #
# The constructor takes the class name, LM hash of the client password  #
# and the LM hash of the client password as arguments.                  #
#########################################################################
sub new_client {
    usage("new_client Authen::NTLM::HTTP(\$lm_hpw, \$nt_hpw\) or\nnew_client Authen::NTLM::HTTP\(\$lm_hpw, \$nt_hpw, \$type, \$user, \$user_domain, \$domain, \$machine\)") unless @_ == 3 or @_ == 4 or @_ == 8;
    my ($package, $lm_hpw, $nt_hpw, $type, $user, $user_domain, $domain, $machine) = @_;
    srand time;
    if (not defined($type)) {$type = NTLMSSP_HTTP_WWW;}
    if (not defined($user)) {$user = $ENV{'USERNAME'};}
    if (not defined($user_domain)) {$user_domain = $ENV{'USERDOMAIN'};}
    if (not defined($domain)) {$domain = Win32::DomainName();}
    if (not defined($machine)) {$machine = $ENV{'COMPUTERNAME'};}
    usage("LM hash must be 21-bytes long") unless length($lm_hpw) == 21;
    usage("NT hash must be 21-bytes long") unless length($nt_hpw) == 21;
    defined($user) or usage "Undefined User Name!\n";
    defined($user_domain) or usage "Undefined User Domain!\n";
    defined($domain) or usage "Undefined Network Domain!\n";
    defined($machine) or usage "Undefined Computer Name!\n";
    my $ctx_id = pack("V", rand 2**32);
    bless {
	'type' => $type,
	'user' => $user,
	'user_domain' => $user_domain,
	'domain' => $domain,
	'machine' => $machine,
	'lm_hpw' => $lm_hpw,
	'nt_hpw' => $nt_hpw
          }, $package;
}

###########################################################################
# new_server instantiate a NTLM server that composes an NTLM challenge    #
# It can take one argument for the server network domain. If the argument #
# is not supplied, it will call Win32::DomainName to obtain it.           #
###########################################################################
sub new_server {
    usage("new_server Authen::NTLM::HTTP or\nnew_server Authen::NTLM::HTTP(\$type, \$domain\)") unless @_ == 1 or @_ == 2 or @_ == 3;
    my ($package, $type, $domain) = @_;
    if (not defined($type)) {$type = NTLMSSP_HTTP_WWW;}
    if (not defined($domain)) {$domain = Win32::DomainName();}
    defined($domain) or usage "Undefined Network Domain!\n";
    bless {
	'type' => $type,
        'domain' => $domain,
	'cChallenge' => 0 # a counter to stir the seed to generate random
          }, $package;    # number for the nonce
}

####################################################################
# http_negotiate creates a NTLM-over-HTTP tag line for NTLM        #
# negotiate packet given the domain (from Win32::DomainName()) and #
# the workstation name (from $ENV{'COMPUTERNAME'} or               #
# Win32::NodeName()) and the negotiation flags.                    #
####################################################################
sub http_negotiate($$)
{
    my $self = shift;
    my $flags = shift;
    my $str = encode_base64($self->SUPER::negotiate_msg($flags));
    $str =~ s/\s//g;
    return "Authorization: NTLM " . $str;
}

###########################################################################
# http_parse_negotiate parses the NTLM-over-HTTP negotiate tag line and   #
# return a list of NTLM Negotiation Flags, Server Network Domain and      #
# Machine name of the client.                                             #
###########################################################################
sub http_parse_negotiate($$)
{
    my ($self, $pkt) = @_;
    $pkt =~ s/Authorization: NTLM //;
    my $str = decode_base64($pkt);
    return $self->SUPER::parse_negotiate($str);
}

####################################################################
# http_challenge composes the NTLM-over-HTTP challenge tag line. It#
# takes NTLM Negotiation Flags as an argument.                     #
####################################################################
sub http_challenge($$)
{
    my $self = $_[0];
    my $flags = $_[1];
    my $nonce = undef;
    my $str;
    $nonce = $_[2] if @_ == 3;
    if (defined $nonce) {
	$str = encode_base64($self->SUPER::challenge_msg($flags, $nonce));
    }
    else {
	$str = encode_base64($self->SUPER::challenge_msg($flags));
    }
    $str =~ s/\s//g;
    return $self->{'type'} . "-Authenticate: NTLM " . $str;
}

###########################################################################
# http_parse_challenge parses the NTLM-over-HTTP challenge tag line and   #
# return a list of server network domain, NTLM Negotiation Flags, Nonce,  #
# ServerContextHandleUpper and ServerContextHandleLower.                  #
###########################################################################
sub http_parse_challenge
{
    my ($self, $pkt) = @_;
    my $str = $self->{'type'} . "-Authenticate: NTLM ";
    $pkt =~ s/$str//;
    $str = decode_base64($pkt);
    return $self->SUPER::parse_challenge($str);
}

###########################################################################
# http_auth creates the NTLM-over-HTTP response to an NTLM challenge from #
# the server. It takes 2 arguments: $nonce obtained from parse_challenge  #
# and NTLM Negotiation Flags. This function ASSUMEs the input of user     #
# domain, user name and workstation name are in ASCII format and not in   #
# UNICODE format.                                                         #
###########################################################################
sub http_auth($$$)
{
    my $self = shift;
    my $nonce = shift;
    my $flags = shift;
    my $str = encode_base64($self->SUPER::auth_msg($nonce, $flags));
    $str =~ s/\s//g;;
    if ($self->{'type'} eq NTLMSSP_HTTP_PROXY) {
	return "Proxy-Authorization: NTLM " . $str;
    }
    else {
	return "Authorization: NTLM " . $str;
    }
}

###########################################################################
# http_parse_auth parses the NTLM-over-HTTP authentication tag line and   #
# return a list of NTLM Negotiation Flags, LM response, NT response, User #
# Domain, User Name, User Machine Name and Session Key.                   #
###########################################################################
sub http_parse_auth($$)
{
    my ($self, $pkt) = @_;
    if ($self->{'type'} eq NTLMSSP_HTTP_PROXY) {
        $pkt =~ s/Proxy-Authorization: NTLM //;
    }
    else {
	$pkt =~ s/Authorization: NTLM //;
    }
    my $str = decode_base64($pkt);
    return $self->SUPER::parse_auth($str);
}

1;

__END__

=head1 NAME

Authen::NTLM::HTTP - Perl extension for NTLM-over-HTTP related computations

=head1 Background

NTLM-over-HTTP Handshake

Stage 1: Client requests a web page.

    1: C  --> S   GET ...

Stage 2: Server responds and says the client needs to authenticate in NTLM manner.

    2: C <--  S   401 Unauthorized
                  WWW-Authenticate: NTLM

Stage 3: Client responds with NTLM negotiate message that contains the identity and the domain of the client.

    3: C  --> S   GET ...
                  Authorization: NTLM <base64-encoded type-1-message>

Stage 4: Server challenges the client with a 8-bytes random number in the NTLM challenge message.

    4: C <--  S   401 Unauthorized
                  WWW-Authenticate: NTLM <base64-encoded type-2-message>

Stage 5: Client responds with a reply that uses its password to encrypt the 8-bytes random number.

    5: C  --> S   GET ...
                  Authorization: NTLM <base64-encoded type-3-message>

Stage 6: Authentication success. Server replies with the web page.

    6: C <--  S   200 Ok

=head1 SYNOPSIS

use Authen::NTLM (nt_hash lm_hash);
use Authen::NTLM::HTTP;

    $my_pass = "mypassword";
# Note: To instantiate a client talking to a proxy, do
# $client = new_client Authen::NTLM::HTTP(lm_hash($my_pass), nt_hash($my_pass), Authen::NTLM::HTTP::NTLMSSP_HTTP_PROXY);
    $client = new_client Authen::NTLM::HTTP(lm_hash($my_pass), nt_hash($my_pass));

# Stage 3 scenario: creates NTLM negotiate message and then
# append $negotiate_msg to one of the tag lines in your HTTP
# request header

# To compose a NTLM Negotiate Packet
    $flags = Authen::NTLM::NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | Authen::NTLM::NTLMSSP_NEGOTIATE_OEM_DOMAIN_SUPPLIED
	   | Authen::NTLM::NTLMSSP_NEGOTIATE_OEM_WORKSTATION_SUPPLIED
	   | Authen::NTLM::NTLMSSP_NEGOTIATE_NTLM
	   | Authen::NTLM::NTLMSSP_NEGOTIATE_UNICODE
	   | Authen::NTLM::NTLMSSP_NEGOTIATE_OEM
    $negotiate_msg = $client->http_negotiate($flags);

# Stage 4 scenario: extract the line contains "Authorization: NTLM "
# in the HTTP header.
# Parses NTLM negotiate message and then generates
# the NTLM challenge message.

# To instantiate a server to parse a NTLM negotiation
# and compose a NTLM challenge
# Note: To instantiate a proxy, do
# $server = new_server Authen::NTLM::HTTP(Authen::NTLM::HTTP::NTLMSSP_HTTP_PROXY);
    $server = new_server Authen::NTLM::HTTP;

    ($flags, $domain, $machine) =
	$server->http_parse_negotiate($negotiate_msg);

    $flags = Authen::NTLM::NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | Authen::NTLM::NTLMSSP_NEGOTIATE_NTLM
	   | Authen::NTLM::NTLMSSP_NEGOTIATE_UNICODE;
    $challenge_msg = $server->http_challenge($flags);

# Stage 5 Scenario: Client receives NTLM challenge message
# Extract the line that contains "WWW-Authenticate: NTLM "
# Pass it to http_parse_challenge to obtain the nonce
# Then use nonce to compose reply with http_auth

# client parse NTLM challenge
    ($domain, $flags, $nonce, $ctx_upper, $ctx_lower) =
	$client->http_parse_challenge($challenge_msg);

# To compose a NTLM Response Packet
    $flags = Authen::NTLM::NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | Authen::NTLM::NTLMSSP_NEGOTIATE_NTLM
	   | Authen::NTLM::NTLMSSP_NEGOTIATE_UNICODE
	   | Authen::NTLM::NTLMSSP_REQUEST_TARGET;
    $auth_msg = $client->http_auth($nonce, $flags);

# Stage 6 Scenario: Finally the server parses the reply
# verify the authentication credentials.

# To parse a NTLM Response Packet
    ($flags, $lm_resp, $nt_resp, $user_domain, $username, $machine) =
	$server->http_parse_auth($auth_msg);

=head1 SEE ALSO

Authen::NTLM(3), MIME::Base64(3), perl(1), m4(1).

=head1 AUTHOR

This implementation was written by Yee Man Chan (ymc@yahoo.com).
Copyright (c) 2002 Yee Man Chan. Some rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
tab-width: 4
End:
