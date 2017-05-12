# -*- perl -*-
# RPC.pm - An implementation of a DCE RPC Composer/Parser. It is expected
# to cover all the connection oriented PDUs. 
# implemented the client side functions that calculates the NTLM response.
# I will add the corresponding server side functions in the next version.
#

package DCE::Perl::RPC;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

*import = \&Exporter::import;

@ISA = qw (Exporter DynaLoader);
@EXPORT = qw ();
@EXPORT_OK = qw ();
$VERSION = '0.01';

# Stolen from Crypt::DES.
sub usage {
    my ($package, $filename, $line, $subr) = caller (1);
    $Carp::CarpLevel = 2;
    croak "Usage: $subr (@_)";
}

# DCE RPC PDU Types
use constant RPC_REQUEST            => 0x00;
use constant RPC_PING               => 0x01;
use constant RPC_RESPONSE           => 0x02;
use constant RPC_FAULT              => 0x03;
use constant RPC_WORKING            => 0x04; 
use constant RPC_NOCALL             => 0x05;
use constant RPC_REJECT             => 0x06;
use constant RPC_ACK                => 0x07;
use constant RPC_CL_CANCEL          => 0x08;
use constant RPC_FACK               => 0x09;
use constant RPC_CANCEL_ACK         => 0x0a;
use constant RPC_BIND               => 0x0b; 
use constant RPC_BIND_ACK           => 0x0c;
use constant RPC_BIND_NACK          => 0x0d;
use constant RPC_ALTER_CONTEXT      => 0x0e;
use constant RPC_ALTER_CONTEXT_RESP => 0x0f;
use constant RPC_BIND_RESP          => 0x10;
use constant RPC_SHUTDOWN           => 0x11; 
use constant RPC_CO_CANCEL          => 0x12;

# DCE RPC PFC Flags
# First Fragment
use constant PFC_FIRST_FRAG => 0x01;
# Last Fragment
use constant PFC_LAST_FRAG => 0x02;
# Cancel was pending at sender
use constant PFC_PENDING_CANCEL => 0x04;
# Reserved
use constant PFC_RESERVED_1 => 0x08;
# supports concurrent multiplexing of a single connection
use constant PFC_CONC_MPX => 0x10;
# only meaningful on 'fault' packet; if true, guaranteed call
# did not execute
use constant PFC_DID_NOT_EXECUTE => 0x20;
# 'maybe' call semantics requested
use constant PFC_MAYBE => 0x40;
# if true, a non-nul object UUID was specified in the handle,
# and is present in the optional object field. If false, the 
# object field is omitted.
use constant PFC_OBJECT_UUID => 0x80;

use constant RPC_MAJOR_VERSION => 5;
use constant RPC_MINOR_VERSION => 0;

# Connection Oriented PDU common header size
use constant RPC_CO_HDR_SZ => 16;

# Fragment Size
use constant RPC_FRAG_SZ => 5840;

use constant RPC_AUTH_NTLM => 0x0a;
use constant RPC_AUTH_LEVEL_CONNECT => 0x02;

#########################################################################
# Constructor to initialize authentication related information. In this #
# version, we assume NTLM as the authentication scheme of choice.       #
# The constructor only takes the class name as an argument.             #
#########################################################################
sub new {
    usage("new DCE::Perl::RPC") unless @_ == 1;
    my ($package) = @_;
    srand time;
    my $ctx_id = pack("V", rand 2**32);
    bless {'auth_type' => RPC_AUTH_NTLM,
	   'auth_level' => RPC_AUTH_LEVEL_CONNECT,
	   'auth_ctx_id' => $ctx_id}, $package;
}

############################################################################
# rpc_co_hdr composes the 16-bytes common DCE RPC header that must present #
# in all conection oriented DCE RPC messages. It takes four arguments:     #
# 1) PDU type; 2) PDU flags; 3) size of the PDU part that is specific to   #
# the PDU type; 4) size of the authentication credentials.                 #
# This function is an internal function. It is not supposed to be called   #
# from the outside world.                                                  #
############################################################################
sub rpc_co_hdr($$$$)
{
    my ($type, $flags, $size, $auth_size) = @_;
    my $msg = chr(RPC_MAJOR_VERSION) . chr(RPC_MINOR_VERSION);
    $msg .= chr($type);
    $msg .= chr($flags);
    $msg .= pack("H8", "10000000"); # assume little endian
    $msg .= pack("v", RPC_CO_HDR_SZ+$size+$auth_size);
    $msg .= pack("v", $auth_size);
    $msg .= pack("V", 0x00); # always 0 for call_id for now
    return $msg;
}

############################################################################
# rpc_auth_hdr composes the 8-bytes authentication header. It takes four   #
# arguments: 1) Authentication Type; 2) Authentication Level; 3) length of #
# padding; 4) context id of this session.                                  #
############################################################################
sub rpc_auth_hdr($$$$)
{
    my ($auth_type, $auth_level, $pad_len, $ctx_id) = @_;
    my $msg = chr($auth_type);
    $msg .= chr($auth_level);
    $msg .= chr($pad_len);
    $msg .= chr(0);
    $msg .= $ctx_id;
    return $msg;
}

#####################################################################
# rpc_bind composes the DCE RPC bind PDU. To make things simple, it #
# assumes the PDU context list only has one element. It takes four  #
# arguments: 1) Presentation Context Id; 2) Abstract Syntax         #
# concatenated with interface version; 3) list of transfer syntax   #
# concatenated with interface version; 4) authentication            # 
# credentials.                                                      #
#####################################################################
sub rpc_bind($$$@$)
{
    my $self = shift;
    my $ctx_id = shift;
    my $abs_syntax = shift;
    my @xfer_syntax = shift;
    my $auth_value = shift;
    my $msg = "";
    my $auth_pad = 0;
    my $i; 
    my $bind_msg = pack("v", RPC_FRAG_SZ) . pack("v", RPC_FRAG_SZ);
    $bind_msg .= pack("V", 0); # ask for new association group id
    $bind_msg .= chr(1) . chr(0) . pack("v", 0);
    $bind_msg .= pack("v", $ctx_id); # ctx id 
    $bind_msg .= chr(@xfer_syntax);
    $bind_msg .= chr(0);
    $bind_msg .= $abs_syntax;
    for ($i = 0; $i < @xfer_syntax; ++$i) {
	$bind_msg .= $xfer_syntax[$i];
    }
    while (length($bind_msg) % 4 != 0) {
	$bind_msg .= chr(0);
	$auth_pad++;
    }
    $bind_msg .= rpc_auth_hdr($self->{'auth_type'}, $self->{'auth_level'}, $auth_pad, $self->{'auth_ctx_id'});
    $msg = rpc_co_hdr(RPC_BIND, PFC_FIRST_FRAG | PFC_LAST_FRAG,
	length($bind_msg), length($auth_value)) . $bind_msg . $auth_value;
    return $msg;
}

##############################################################################
# rpc_bind_resp composes the DCE RPC bind_resp PDU. This PDU is undocumented #
# in the OpenGroup's specification but it is used by DCOM. It's main         #
# responsibility is to respond to the NTLM challenge posted by the bind_ack  #
# PDU from the server. Its lone argument is the NTLM response.               #
##############################################################################
sub rpc_bind_resp($$)
{
    my $self = shift;
    my $auth_value = shift;
    my $msg = "";
    my $auth_pad = 0;
    my $i; 
    my $bind_resp_msg = pack("v", RPC_FRAG_SZ) . pack("v", RPC_FRAG_SZ);
    while (length($bind_resp_msg) % 4 != 0) {
	$bind_resp_msg .= chr(0);
	$auth_pad++;
    }
    $bind_resp_msg .= rpc_auth_hdr($self->{'auth_type'}, $self->{'auth_level'}, $auth_pad, $self->{'auth_ctx_id'});
    $msg = rpc_co_hdr(RPC_BIND_RESP, PFC_FIRST_FRAG | PFC_LAST_FRAG,
	length($bind_resp_msg), length($auth_value)) . $bind_resp_msg . $auth_value;
    return $msg;
}

###########################################################################
# rpc_co_request composes the connection-oriented DCE RPC Request PDU. It #
# takes five arguments: 1) the stub; 2) the presentation context id;      #
# 3) operation # within the interface; 4) object UUID; 5) authetication   #
# credentials. The fourth argument can be "" if there is no UUID          #
# associate with this request PDU.                                        #
########################################################################### 
sub rpc_co_request($$$$$$)
{
    my ($self, $body, $ctx_id, $op_num, $uuid, $auth_value) = @_; 
    my $msg = "";
    my $auth_pad = 0;
    my $i;
    my $flags = PFC_FIRST_FRAG | PFC_LAST_FRAG; 
    my $req_msg = pack("V", length($body));
    $req_msg .= pack("v", $ctx_id);
    $req_msg .= pack("v", $op_num);
    if (defined($uuid) and length($uuid) == 16) {
	$flags |= PFC_OBJECT_UUID;
	$req_msg .= $uuid;
    }
    $req_msg .= $body;
    while (length($req_msg) % 4 != 0) {
	$req_msg .= chr(0);
	$auth_pad++;
    }
    $req_msg .= rpc_auth_hdr($self->{'auth_type'}, $self->{'auth_level'}, $auth_pad, $self->{'auth_ctx_id'});
    $msg = rpc_co_hdr(RPC_REQUEST, $flags,
	length($req_msg), length($auth_value)) . $req_msg . $auth_value;
    return $msg;
}

##########################################################################
# rpc_alt_ctx composes a DCE RPC alter_context PDU. alter_context PDU is #
# used to change the presentation syntax established by the earlier bind #
# PDU. Therefore it has similar format. However, there is no need for    #
# authentication credentials. Like rpc_bind, we also assume the          #
# presentation context list only has one element.                        #
##########################################################################
sub rpc_alt_ctx($$$@)
{
    my $self = shift;
    my $ctx_id = shift;
    my $abs_syntax = shift;
    usage("Abstract Syntax plus interface version must be 20-bytes long!") unless length($abs_syntax) == 20;
    my @xfer_syntax = shift;
    my $msg = "";
    my $i; 
    my $alt_ctx_msg = pack("v", RPC_FRAG_SZ) . pack("v", RPC_FRAG_SZ);
    $alt_ctx_msg .= pack("V", 0); # ask for new association group id
    $alt_ctx_msg .= chr(1) . chr(0) . pack("v", 0);
    $alt_ctx_msg .= pack("v", $ctx_id); # ctx id 
    $alt_ctx_msg .= chr(@xfer_syntax);
    $alt_ctx_msg .= chr(0);
    $alt_ctx_msg .= $abs_syntax;
    for ($i = 0; $i < @xfer_syntax; ++$i) {
	$alt_ctx_msg .= $xfer_syntax[$i];
    }
    $msg = rpc_co_hdr(RPC_ALTER_CONTEXT, PFC_FIRST_FRAG | PFC_LAST_FRAG,
	length($alt_ctx_msg), 0) . $alt_ctx_msg;
    return $msg;
}

1;

__END__

=head1 NAME

DCE::Perl::RPC - Perl extension for DCE RPC protocol composer/parser

=head1 SYNOPSIS

use DCE::Perl::RPC;
use constant DCOM_IREMOTEACTIVATION => pack("H32", "B84A9F4D1C7DCF11861E0020AF6E7C57");
use constant DCOM_IF_VERSION => pack("V", 0);
use constant DCOM_XFER_SYNTAX => pack("H32", "045D888AEB1CC9119FE808002B104860");
use constant DCOM_XFER_SYNTAX_VERSION => pack("V", 2);

    $rpc = new DCE::Perl::RPC;
    $bind_msg = $rpc->rpc_bind(1, DCOM_IREMOTEACTIVATION . DCOM_IF_VERSION,
	(DCOM_XFER_SYNTAX . DCOM_XFER_SYNTAX_VERSION, $nltm_negotiate_msg);
    $bind_resp_msg = $rpc->rpc_bind_resp($ntlm_auth_msg);
    $request_msg = $rpc->rpc_co_request("Hi, there! This is Stub!", 1, 0x0e, DCOM_IREMOTEACTIVATION, "Authentication Credentials");
    $alt_ctx_msg = $rpc->rpc_alt_ctx(1, DCOM_IREMOTEACTIVATION . DCOM_IF_VERSION,
	(DCOM_XFER_SYNTAX . DCOM_XFER_SYNTAX_VERSION));

=head1 DESCRIPTION

The DCE RPC protocol is an application level protocol from OpenGroup
that allows applications to do Remote Procedure Calls. It is the 
underlying wire protocol for DCOM (Distributed Common Object Model)
by Microsoft. 
 
This module was motivated by an reverse-engineering effort on a DCOM
client. Therefore, functions that are implemented gear more toward
client side implementation. Also, the initial version only supports
Connection Oriented version of DCE RPC. It also assumes NTLMSSP as 
the underlying authentication protocol. This can change based on the
input of the users of this modules.

=head1 DEPENDENCIES

There is no dependencies for this module. However, to build a DCOM
client running in Microsoft environment, you may need to install
an NTLM module such as Authen::Perl::NTLM.

=head1 ASSUMPTIONS

1) The version of DCE RPC Connection Oriented protocol supported is 5.0.

2) NTLM is the authentication scheme of choice.

3) AUTH_LEVEL_CONNECT is the authentication level of choice.

4) Network Data Representation (NDR) is assumed to be ASCII for characters,
little endian for integers and IEEE for floating points.

5) Call Id is always zero. It seems to me my client works regardless of
the value of call id.

=head1 TO-DO

1) Support fragmented CO Requests.

2) Put authentication type as an argument in the constructor.

3) Implement Connection Oriented server side functions. 

4) Implement Connection-less functions. 

5) Implement the module in C.

=head1 BUGS

Nothing known. 

=head1 AUTHOR

This implementation was written by Yee Man Chan (ymc@yahoo.com).
Copyright (c) 2002 Yee Man Chan. All rights reserved. This program 
is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself. 

=head1 SEE ALSO

Authen::Perl::NTLM(3), perl(1), m4(1).

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
