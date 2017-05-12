# ACE4.pm
#
# Interface to Securid ACE/Server client API
# Copyright (C) 2001 Open System Consultants
# Author: Mike McCauley mikem@open.com.au
# $Id: ACE4.pm,v 1.2 2011/12/29 06:03:24 mikem Exp mikem $

package Authen::ACE4;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# These are all you really need
@EXPORT_OK = qw(
	AceInitialize
	AceStartAuth
	AceContinueAuth
	AceCloseAuth
	AceAceGetAuthenticationStatus
	AceGetAlphanumeric
	AceGetMaxPinLen
	AceGetMinPinLen
	AceGetShell
	AceGetSystemPin
	AceGetTime
	AceGetUserSelectable
	AceCloseAuth
	ACM_OK
	ACM_ACCESS_DENIED
	ACE_SUCCESS
);
$VERSION = '1.4';

sub AUTOLOAD {
    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Undefined ACE4 macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Authen::ACE4 $VERSION;


package Authen::ACE4::Sync;

use Authen::ACE4;

sub Pin {
    my $self = shift;
    my $pin = shift;

    return SD_Pin($self->{sd}, $pin);
}

sub Next {
    my $self = shift;
    my $token = shift;

    return SD_Next($self->{sd}, $token);
}

sub Check {
    my $self = shift;
    my ($passcode, $username) = @_;

    return SD_Check($self->{sd}, $passcode, $username);
}

sub new {
    my $type = shift;
    my $self = {};

    $ENV{"VAR_ACE"} = "/var/ace" unless defined($ENV{"VAR_ACE"});

    if (Authen::ACE4::AceInitialize() != 1) {
        die "Could not read ACE client configuration file in " .
	    $ENV{"VAR_ACE"} . "\n";
    }

    $self->{sd} = 0;
    if (SD_Init($self->{sd}) != Authen::ACE4::ACM_OK()) {
      die "Failed call to SD_Init\n";
    }

    bless $self, $type;
}

sub DESTROY {
    my $self = shift;

    SD_Close($self->{sd});
}


1;
__END__
=pod

=head1 NAME

Authen::ACE4 - Perl extension for accessing a SecurID ACE server or RSA Authenticaiotn Manager

=head1 SYNOPSIS

use Authen::ACE4;
AceInitialize();
($result, $handle, $moreData, $echoFlag, $respTimeout, 
 $nextRespLen, $prompt)
    = AceStartAuth($username);
($result, $moreData, $echoFlag, $respTimeout, 
 $nextRespLen, $prompt) 
    = Authen::ACE4::AceContinueAuth($handle, $resp);
($result, $status) 
    = Authen::ACE4::AceGetAuthenticationStatus($handle);
$result = AceCloseAuth($handle);

=head1 DESCRIPTION

Authen::ACE4 provides a client interface to a Security Dynamics SecurID
ACE server. It uses the ACE/Agent client libraries.
SecurID authentication can be added to any Perl
application using Authen::ACE4.

Synchronous functions are provided for authenticating users and
getting some user information.  Asynchronous functions are not
supported. ACE/Agent Version 4.1 and better API is supported. Legacy
functions like sd_auth etc are not supported.

=head1 METHODS

=over 4

=item AceInitialize

AceInitialize();

Initializes the ACE client access library and loads the ACE
configuration file (sdconf.rec). AceInitialize must be called
before any other API function is called.

On Unix, the environment variable VAR_ACE is used to find
the ACE/Server sdconf.rec file, which specifies how to
contact the ACE server and/or Authentication Manager. The
default is /var/ace/data. If your sdconf.rec is in a different location
you must specify VAR_ACE eg:

    $ENV{VAR_ACE} = '/opt/ace/data';

before calling AceInitialize.

=item AceStartAuth

($result, $handle, $moreData, $echoFlag, $respTimeout, 
$nextRespLen, $prompt) 
    = Authen::ACE4::AceStartAuth($username);

The AceStartAuth function is designed to be used aling with 
AceContinueAuth and AceCloseAuth.

AceStartAuth is the first step in authenticating a user. If the
function returns successfully, continue to call AceContinueAuth as
long as $moreData is true.

If AceStartAuth returns successfully, AceCloseAuth must be called
to close the authentication context. If AceStartAuth 
does not return successfully, AceCloseAuth must not be called.

You can have multiple authentication contexts (handles) current
at the same time. Each one must be closed with its own AceCloseAuth.

Input data is

=over 4

=item username

The name of the user to be authenticated, as known to the ACE/Server.

=back

Returned data is

=over 4

=item result

Indicates the success or failure of the call (but not success
of the authentication, see AceGetAuthenticationStatus for that).

If the call succeeds, $handle, $moreData etc will be set. If 
the call fails, only $result and $prompt will have meaningful values.

Possible results for $result are

=over 4

=item ACM_OK

The call succeeded. $handle contains the handle for this context

=item ACE_INIT_NO_RESOURCE

Memory allocation error

=item ACE_EVENT_CREATE_FAIL

Could not create event object and associated data.

=item ACE_INIT_SOCKET_FAIL

Could not open and/or create a socket

=back

=item handle

Returns a new opaque handle for this authentication context.

=item moreData

A flag that indicate whether more data is needed by the 
authentication context.

=item echoFlag

A flag that gives a hint to the developer whether the next response
should be echoed on the screen.

=item respTimeout

A hint to the developer about how long to display this prompt
string to the user.

=item nextRespLen

Indicates the maximum number of bytes of data expected in the next
call to AceContinueAuth

=item prompt

Message string that should be shown to the user as the request for
data to be passed to the next call to AceContinueAuth.

=back

=item AceContinueAuth

($result, $moreData, $echoFlag, $respTimeout, 
     $nextRespLen, $prompt) 
	= Authen::ACE4::AceContinueAuth($handle, $resp);


AceContinueAuth should continue to be called for as long as
it succeeds and $moreData is true. Each successive call will 
ask for additional data required for the authentication to be
entered by the user.

After AceContinueAuth returns with moreDat false, use 
AceGetAuthenticationStatus to check the result of the
completed authentication process.

Input data is
 
=over 4

=item handle

The opaque handle for this authentication context, previously returned
by AceStartAuth.

=item resp

The response from the user to the prompt from the previous AceStartAuth
or AceContinueAuth.

=back

Returned data is

=over 4

=item result

Indicates the success or failure of the call (but not success
of the authentication, see AceGetAuthenticationStatus for that).

If the call succeeds, $moreData, $echoFlag etc will be set. If 
the call fails, only $result and $prompt will have meaningful values.

Possible results for $result are

=over 4

=item ACM_OK

The call succeeded. $handle contains the handle for this context

=item ACE_CHECK_INVALID_HANDLE

Handle is invalid

=back

=item moreData

A flag that indicate whether more data is needed by the 
authentication context.

=item echoFlag

A flag that gives a hint to the developer whether the next response
should be echoed on the screen.

=item respTimeout

A hint to the developer about how long to display this prompt
string to the user.

=item nextRespLen

Indicates the maximum number of bytes of data expected in the next
call to AceContinueAuth

=item prompt

Message string that should be shown to the user as the request for
data to be passed to the next call to AceContinueAuth.

=back

=item AceGetAuthenticationStatus

($result, $status) = Authen::ACE4::AceGetAuthenticationStatus($handle);

Returns the status of the request. Can be called at any stage during
the authentication process.

Returned data is

=over 4

=item result

Indicates the success or failure of the call (but not success
of the authentication, see $status for that).

Possible results for $result are

=over 4

=item ACE_SUCCESS

The call succeeded. $status contains the status for this context. Note 
that it is not correct to compare this with ACM_OK.

=item ACE_CHECK_INVALID_HANDLE

Handle is invalid

=back

=item status

Indicates the current status of this authentication

Possible results for $status are

=over 4

=item ACM_NEXT_CODE_REQUIRE

=item ACM_ACCESS_DENIED

=item ACM_NEW_PIN_REQUIRED

=item ACM_NEW_PIN_ACCEPTED

=item ACM_NEW_PIN_REJECTED

=item ACM_NEXT_CODE_BAD

=back

=back

=item AceCloseAuth

$result = Authen::ACE4::AceCloseAuth($handle);

Closes a previously created authentication context, and frees 
any memory that was allocated. Every successful
AceStartAuth must have a matching AceCloseAuth. It can be called
at any time after AceStartAuth. $handle must be the handle returned
by a previous call to AceStartAuth.

Returns ACM_OK if successful.

=back

=head1 AUTHOR

Mike McCauley <mikem@open.com.au>

Copyright (C) 2000 OPen System Consultants Pty Ltd. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), ACE/Server Administration Manual, ACE/Server v 4.1
Authentication API Guide, Authen::ACE

=cut
