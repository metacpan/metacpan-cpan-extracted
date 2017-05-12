# -*- perl -*-
# NTLM.pm - An implementation of NTLM. In this version, I only
# implemented the client side functions that calculates the NTLM response.
# I will add the corresponding server side functions in the next version.
#

package Authen::Perl::NTLM;

use strict;
use POSIX;
use Carp;
$Authen::Perl::NTLM::PurePerl = undef; # a flag to see if we load pure perl 
                                       # DES and MD4 modules
eval "require Crypt::DES && require Digest::MD4";
if ($@) {
    eval "require Crypt::DES_PP && require Digest::Perl::MD4";
    if ($@) {
	die "Required DES and/or MD4 module doesn't exist!\n";
    }
    else {
        $Authen::Perl::NTLM::PurePerl = 1;
    }
}
else {
    $Authen::Perl::NTLM::PurePerl = 0;
}

if ($Authen::Perl::NTLM::PurePerl == 1) {
    require Crypt::DES_PP;
    Crypt::DES_PP->import;
    require Digest::Perl::MD4;
    import Digest::Perl::MD4 qw(md4);
}
else {
    require Crypt::DES;
    Crypt::DES->import;
    require Digest::MD4;
    import Digest::MD4;
}
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

*import = \&Exporter::import;

@ISA = qw (Exporter DynaLoader);
@EXPORT = qw ();
@EXPORT_OK = qw (nt_hash lm_hash calc_resp);
$VERSION = '0.12';

# Stolen from Crypt::DES.
sub usage {
    my ($package, $filename, $line, $subr) = caller (1);
    $Carp::CarpLevel = 2;
    croak "Usage: $subr (@_)";
}

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

sub lm_hash($);
sub nt_hash($);
sub calc_resp($$);

#########################################################################
# Constructor to initialize authentication related information. In this #
# version, we assume NTLM as the authentication scheme of choice.       #
# The constructor takes the class name, LM hash of the client password  #
# and the LM hash of the client password as arguments.                  #
#########################################################################
sub new_client {
    usage("new_client Authen::Perl::NTLM(\$lm_hpw, \$nt_hpw\) or\nnew_client Authen::Perl::NTLM\(\$lm_hpw, \$nt_hpw, \$user, \$user_domain, \$domain, \$machine\)") unless @_ == 3 or @_ == 7;
    my ($package, $lm_hpw, $nt_hpw, $user, $user_domain, $domain, $machine) = @_;
    srand time;
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
    usage("new_server Authen::Perl::NTLM or\nnew_server Authen::Perl::NTLM(\$domain\)") unless @_ == 1 or @_ == 2;
    my ($package, $domain) = @_;
    if (not defined($domain)) {$domain = Win32::DomainName();}
    defined($domain) or usage "Undefined Network Domain!\n";
    bless {
        'domain' => $domain,
	'cChallenge' => 0 # a counter to stir the seed to generate random
          }, $package;    # number for the nonce
}

##########################################################################
# lm_hash calculates the LM hash to be used to calculate the LM response #
# It takes a password and return the 21 bytes LM password hash.          #
##########################################################################
sub lm_hash($)
{
    my ($passwd) = @_;
    my $cipher1;
    my $cipher2;
    my $magic = pack("H16", "4B47532140232425"); # magical string to be encrypted for the LM password hash
    while (length($passwd) < 14) {
	$passwd .= chr(0);
    }
    my $lm_pw = substr($passwd, 0, 14);
    $lm_pw = uc($lm_pw); # change the password to upper case
    my $key = convert_key(substr($lm_pw, 0, 7)) . convert_key(substr($lm_pw, 7, 7));
    if ($Authen::Perl::NTLM::PurePerl) {
	$cipher1 = Crypt::DES_PP->new(substr($key, 0, 8));
	$cipher2 = Crypt::DES_PP->new(substr($key, 8, 8));
    }
    else {
	$cipher1 = Crypt::DES->new(substr($key, 0, 8));
	$cipher2 = Crypt::DES->new(substr($key, 8, 8));
    }
    return $cipher1->encrypt($magic) . $cipher2->encrypt($magic) . pack("H10", "0000000000");
} 

##########################################################################
# nt_hash calculates the NT hash to be used to calculate the NT response #
# It takes a password and return the 21 bytes NT password hash.          #
##########################################################################
sub nt_hash($)
{
    my ($passwd) = @_;
    my $nt_pw = unicodify($passwd);
    my $nt_hpw;
    if ($Authen::Perl::NTLM::PurePerl == 1) {
	$nt_hpw = md4($nt_pw) . pack("H10", "0000000000");
    }
    else {
	my $md4 = new Digest::MD4;
        $md4->add($nt_pw);
	$nt_hpw = $md4->digest() . pack("H10", "0000000000");
    }
    return $nt_hpw;
}

####################################################################
# negotiate_msg creates the NTLM negotiate packet given the domain #
# (from Win32::DomainName()) and the workstation name (from        #
# $ENV{'COMPUTERNAME'} or Win32::NodeName()) and the negotiation   #
# flags.							   #
####################################################################
sub negotiate_msg($$)
{
    my $self = $_[0];
    my $flags = pack("V", $_[1]);
    my $domain = $self->{'domain'};
    my $machine = $self->{'machine'};
    my $msg = NTLMSSP_SIGNATURE . chr(0);
    $msg .= pack("V", NTLMSSP_NEGOTIATE);
    $msg .= $flags;
    my $offset = length($msg) + 8*2;
    $msg .= pack("v", length($domain)) . pack("v", length($domain)) . pack("V", $offset + length($machine)); 
    $msg .= pack("v", length($machine)) . pack("v", length($machine)) . pack("V", $offset);
    $msg .= $machine . $domain;
    return $msg;
}

####################################################################
# challenge_msg composes the NTLM challenge message. It takes NTLM #
# Negotiation Flags as an argument.                                # 
####################################################################
sub challenge_msg($)
{
    my ($self) = @_;
    my $flags = pack("V", $_[1]);
    my $domain = $self->{'domain'};
    my $msg = NTLMSSP_SIGNATURE . chr(0);
    $self->{'cChallenge'} += 0x100;
    $msg .= pack("V", NTLMSSP_CHALLENGE);
    $msg .= pack("v", length($domain)) . pack("v", length($domain)) . pack("V", 48);
    $msg .= $flags;
    $msg .= compute_nonce($self->{'cChallenge'});
    $msg .= pack("VV", 0, 0); # 8 bytes of reserved 0s
    $msg .= pack("V", 0); # ServerContextHandleLower
    $msg .= pack("V", 0x3c); # ServerContextHandleUpper
    $msg .= unicodify($domain);
    return $msg;
}

###########################################################################
# parse_challenge parses the NTLM challenge and return a list of server   #
# network domain, NTLM Negotiation Flags, Nonce, ServerContextHandleUpper #
# and ServerContextHandleLower.                                           #
########################################################################### 
sub parse_challenge
{
    my ($self, $pkt) = @_;
    substr($pkt, 0, 8) eq (NTLMSSP_SIGNATURE . chr(0)) or usage "NTLM Challenge doesn't contain NTLMSSP_SIGNATURE!\n";
    my $type = GetInt32(substr($pkt, 8));
    $type == NTLMSSP_CHALLENGE or usage "Not an NTLM Challenge!\n";
    my $target = GetString($pkt, 12);
    $target = un_unicodify($target);
    my $flags = GetInt32(substr($pkt, 20));
    my $nonce = substr($pkt, 24, 8);
    my $ctx_lower = GetInt32(substr($pkt, 40));
    my $ctx_upper = GetInt32(substr($pkt, 44));
    return ($target, $flags, $nonce, $ctx_lower, $ctx_upper);
}

############################################################################
# GetString is called internally to get a UNICODE string in a NTLM message #
############################################################################
sub GetString
{
    my ($str, $loc) = @_;
    my $len = GetInt16(substr($str, $loc));
    my $max_len = GetInt16(substr($str, $loc+2));
    my $offset = GetInt32(substr($str, $loc+4));
    return substr($str, $offset, 2*$max_len);
}

############################################################################
# GetInt32 is called internally to get a 32-bit integer in an NTLM message #
############################################################################
sub GetInt32
{
    my ($str) = @_;
    return unpack("V", substr($str, 0, 4));
}

############################################################################
# GetInt16 is called internally to get a 16-bit integer in an NTLM message #
############################################################################
sub GetInt16
{
    my ($str) = @_;
    return unpack("v", substr($str, 0, 2));
}

###########################################################################
# auth_msg creates the NTLM response to an NTLM challenge from the        #
# server. It takes 2 arguments: $nonce obtained from parse_challenge and  #
# NTLM Negotiation Flags.                                                 #
# This function ASSUMEs the input of user domain, user name and           # 
# workstation name are in ASCII format and not in UNICODE format.         #
###########################################################################
sub auth_msg($$$)
{
    my ($self, $nonce) = @_;
    my $session_key = session_key();
    my $user_domain = $self->{'user_domain'};
    my $username = $self->{'user'};
    my $machine = $self->{'machine'};
    my $lm_resp = calc_resp($self->{'lm_hpw'}, $nonce);
    my $nt_resp = calc_resp($self->{'nt_hpw'}, $nonce);
    my $flags = pack("V", $_[2]);
    my $msg = NTLMSSP_SIGNATURE . chr(0);
    $msg .= pack("V", NTLMSSP_AUTH);
    my $offset = length($msg) + 8*6 + 4;
    $msg .= pack("v", length($lm_resp)) . pack("v", length($lm_resp)) . pack("V", $offset + 2*length($user_domain) + 2*length($username) + 2*length($machine) + length($session_key)); 
    $msg .= pack("v", length($nt_resp)) . pack("v", length($nt_resp)) . pack("V", $offset + 2*length($user_domain) + 2*length($username) + 2*length($machine) + length($session_key) + length($lm_resp)); 
    $msg .= pack("v", 2*length($user_domain)) . pack("v", 2*length($user_domain)) . pack("V", $offset); 
    $msg .= pack("v", 2*length($username)) . pack("v", 2*length($username)) . pack("V", $offset + 2*length($user_domain)); 
    $msg .= pack("v", 2*length($machine)) . pack("v", 2*length($machine)) . pack("V", $offset + 2*length($user_domain) + 2*length($username)); 
    $msg .= pack("v", length($session_key)) . pack("v", length($session_key)) . pack("V", $offset + 2*length($user_domain) + 2*length($username) + 2*length($machine)+ 48); 
    $msg .= $flags . unicodify($user_domain) . unicodify($username) . unicodify($machine) . $lm_resp . $nt_resp . $session_key;
    return $msg;
}

#####################################################################
# session_key computes a session key for an NTLM session. Currently #
# it is not implemented.                                            #
#####################################################################
sub session_key
{
    return "";
}

#######################################################################
# compute_nonce computes the 8-bytes nonce to be included in server's
# NTLM challenge packet.
#######################################################################
sub compute_nonce($)
{
   my ($cChallenge) = @_;
   my @SysTime = UNIXTimeToFILETIME($cChallenge, time);
   my $Seed = (($SysTime[1] + 1) <<  0) |
              (($SysTime[2] + 0) <<  8) |
              (($SysTime[3] - 1) << 16) |
              (($SysTime[4] + 0) << 24);
   srand $Seed;
   my $ulChallenge0 = rand(2**16)+rand(2**32); 
   my $ulChallenge1 = rand(2**16)+rand(2**32); 
   my $ulNegate = rand(2**16)+rand(2**32);
   if ($ulNegate & 0x1) {$ulChallenge0 |= 0x80000000;} 
   if ($ulNegate & 0x2) {$ulChallenge1 |= 0x80000000;} 
   return pack("V", $ulChallenge0) . pack("V", $ulChallenge1);
}

#########################################################################
# convert_key converts a 7-bytes key to an 8-bytes key based on an 
# algorithm.
#########################################################################
sub convert_key($) {
    my ($in_key) = @_; 
    my @byte;
    my $result = "";
    usage("exactly 7-bytes key") unless length($in_key) == 7;
    $byte[0] = substr($in_key, 0, 1);
    $byte[1] = chr(((ord(substr($in_key, 0, 1)) << 7) & 0xFF) | (ord(substr($in_key, 1, 1)) >> 1));
    $byte[2] = chr(((ord(substr($in_key, 1, 1)) << 6) & 0xFF) | (ord(substr($in_key, 2, 1)) >> 2));
    $byte[3] = chr(((ord(substr($in_key, 2, 1)) << 5) & 0xFF) | (ord(substr($in_key, 3, 1)) >> 3));
    $byte[4] = chr(((ord(substr($in_key, 3, 1)) << 4) & 0xFF) | (ord(substr($in_key, 4, 1)) >> 4));
    $byte[5] = chr(((ord(substr($in_key, 4, 1)) << 3) & 0xFF) | (ord(substr($in_key, 5, 1)) >> 5));
    $byte[6] = chr(((ord(substr($in_key, 5, 1)) << 2) & 0xFF) | (ord(substr($in_key, 6, 1)) >> 6));
    $byte[7] = chr((ord(substr($in_key, 6, 1)) << 1) & 0xFF);
    for (my $i = 0; $i < 8; ++$i) {
	$byte[$i] = set_odd_parity($byte[$i]);
	$result .= $byte[$i];
    }
    return $result;
}

##########################################################################
# set_odd_parity turns one-byte into odd parity. Odd parity means that 
# a number in binary has odd number of 1's.
##########################################################################
sub set_odd_parity($)
{
    my ($byte) = @_;
    my $parity = 0;
    my $ordbyte;
    usage("single byte input only") unless length($byte) == 1;
    $ordbyte = ord($byte);
    for (my $i = 0; $i < 8; ++$i) {
	if ($ordbyte & 0x01) {++$parity;}
	$ordbyte >>= 1;
    }
    $ordbyte = ord($byte);
    if ($parity % 2 == 0) {
	if ($ordbyte & 0x01) {
	    $ordbyte &= 0xFE;
	}
	else {
	    $ordbyte |= 0x01;
	}
    }
    return chr($ordbyte);
}

###########################################################################
# calc_resp computes the 24-bytes NTLM response based on the password hash
# and the nonce.
###########################################################################
sub calc_resp($$)
{
    my ($key, $nonce) = @_;
    my $cipher1;
    my $cipher2;
    my $cipher3; 
    usage("key must be 21-bytes long") unless length($key) == 21;
    usage("nonce must be 8-bytes long") unless length($nonce) == 8;
    if ($Authen::Perl::NTLM::PurePerl) {
	$cipher1 = Crypt::DES_PP->new(convert_key(substr($key, 0, 7)));
	$cipher2 = Crypt::DES_PP->new(convert_key(substr($key, 7, 7)));
	$cipher3 = Crypt::DES_PP->new(convert_key(substr($key, 14, 7)));
    }
    else {
	$cipher1 = Crypt::DES->new(convert_key(substr($key, 0, 7)));
	$cipher2 = Crypt::DES->new(convert_key(substr($key, 7, 7)));
	$cipher3 = Crypt::DES->new(convert_key(substr($key, 14, 7)));
    }
    return $cipher1->encrypt($nonce) . $cipher2->encrypt($nonce) . $cipher3->encrypt($nonce);
}

#########################################################################
# un_unicodify takes a unicode string and turns it into an ASCII string.
# CAUTION: This function is intended to be used with unicodified ASCII
# strings.
#########################################################################
sub un_unicodify
{
   my ($str) = @_;
   my $newstr = "";
   my $i;

   usage("$str must be a string of even length to be un_unicodify!: $!\n") if length($str) % 2;

   for ($i = 0; $i < length($str) / 2; ++$i) {
	$newstr .= substr($str, 2*$i, 1);
   }
   return $newstr;
}

#########################################################################
# unicodify takes an ASCII string and turns it into a unicode string.
#########################################################################
sub unicodify($)
{
   my ($str) = @_;
   my $newstr = "";
   my $i;

   for ($i = 0; $i < length($str); ++$i) {
 	$newstr .= substr($str, $i, 1) . chr(0);
   }
   return $newstr;
}

##########################################################################
# UNIXTimeToFILETIME converts UNIX time_t to 64-bit FILETIME format used
# in win32 platforms. It returns two 32-bit integer. The first one is 
# the upper 32-bit and the second one is the lower 32-bit. The result is
# adjusted by cChallenge as in NTLM spec. For those of you who want to
# use this function for actual use, please remove the cChallenge variable.
########################################################################## 
sub UNIXTimeToFILETIME($$)
{
    my ($cChallenge, $time) = @_;
    $time = $time * 10000000 + 11644473600000000 + $cChallenge;
    my $uppertime = $time / (2**32);
    my $lowertime = $time - floor($uppertime) * 2**32;
    return ($lowertime & 0x000000ff, 
	    $lowertime & 0x0000ff00,
	    $lowertime & 0x00ff0000,
	    $lowertime & 0xff000000,
	    $uppertime & 0x000000ff,
	    $uppertime & 0x0000ff00,
	    $uppertime & 0x00ff0000,
	    $uppertime & 0xff000000);
}

1;

__END__

=head1 NAME

Authen::Perl::NTLM - Perl extension for NTLM related computations

=head1 SYNOPSIS

use Authen::Perl::NTLM qw(nt_hash lm_hash);

    $my_pass = "mypassword";
    $client = new_client Authen::Perl::NTLM(lm_hash($my_pass), nt_hash($my_pass));

# To compose a NTLM Negotiate Packet
    $flags = Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_80000000 
	   | Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_128
	   | Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_OEM_DOMAIN_SUPPLIED
	   | Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_OEM_WORKSTATION_SUPPLIED
	   | Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_NTLM
	   | Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_UNICODE
	   | Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_OEM
	   | Authen::Perl::NTLM::NTLMSSP_REQUEST_TARGET;
    $negotiate_msg = $client->negotiate_msg($flags);

# To instantiate a server to compose a NTLM challenge
    $server = new_server Authen::Perl::NTLM;
    $flags = Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_NTLM
	   | Authen::Perl::NTLM::NTLMSSP_REQUEST_INIT_RESPONSE
	   | Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_UNICODE
	   | Authen::Perl::NTLM::NTLMSSP_REQUEST_TARGET;
    $challenge_msg = $server->challenge_msg($flags);

# client parse NTLM challenge
    ($domain, $flags, $nonce, $ctx_upper, $ctx_lower) = 
	$client->parse_challenge($challenge_msg);

# To compose a NTLM Response Packet
    $flags = Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_NTLM
	   | Authen::Perl::NTLM::NTLMSSP_NEGOTIATE_UNICODE
	   | Authen::Perl::NTLM::NTLMSSP_REQUEST_TARGET;
    $auth_msg = $client->auth_msg($nonec, $flags);

=head1 DESCRIPTION

The NTLM (Windows NT LAN Manager) authentication scheme is the authentication
algorithm used by Microsoft. 

NTLM authentication scheme is used in DCOM and HTTP environment. 
It is used to authenticate DCE RPC packets in DCOM. It is also used to
authenticate HTTP packets to MS Web Proxy or MS Web Server.

Currently, it is the authentication scheme Internet Explorer chooses to
authenticate itself to proxies/web servers that supports NTLM.

As of this version, NTLM module only provides the client side functions
to calculate NT response and LM response. The next revision will provide
the server side functions that computes the nonce and verify the NTLM responses.

This module was written without the knowledge of Mark Bush's (MARKBUSH)
NTLM implementation. It was used by Yee Man Chan to implement a Perl
DCOM client.

=head1 DEPENDENCIES

To use this module, please install the one of the following two sets of
DES and MD4 modules:

1) Crypt::DES module by Dave Paris (DPARIS) and Digest::MD4 module by 
Mike McCauley (MIKEM) first. These two modules are implemented in C.

2) Crypt::DES_PP module by Guido Flohr (GUIDO) and Digest::Perl::MD4
module by Ted Anderson (OTAKA). These two modules are implemented
in Perl.

The first set of modules will be preferred by NTLM because they are
supposedly faster.

=head1 TO-DO

1) A function to parse NTLM negotiation packet for DCE RPC. 

2) A function to parse NTLM response packet for DCE RPC. 

3) A function to compute session key for DCE RPC.

4) Implement the module in C.

=head1 BUGS

Nothing known. 

=head1 AUTHOR

This implementation was written by Yee Man Chan (ymc@yahoo.com).
Copyright (c) 2002 Yee Man Chan. All rights reserved. This program 
is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself. 

=head1 SEE ALSO

Digest::MD4(3), Crypt::DES(3), perl(1), m4(1).

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
