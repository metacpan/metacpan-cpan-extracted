package Crypt::U2F::Server::Simple;

use 5.018001;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA     = qw(Exporter);
our $VERSION = '0.47';

use Crypt::U2F::Server;

my $refCount = 0;
my $errstr   = '';

our %EXPORT_TAGS = ( 'all' => [qw()] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();

my $maxStringLength = 10_000;

sub new {
    my ( $proto, %config ) = @_;
    my $class = ref($proto) || $proto;

    foreach my $key (qw[appId origin]) {
        if ( !defined( $config{$key} ) ) {
            croak("$key not defined!");
        }
        if ( !length( $config{$key} ) ) {
            croak("$key must not be empty!");
        }
    }

    my $self = bless \%config, $class;

    $config{debug} //= 0;

    if ( !$refCount ) {
        my $rc = Crypt::U2F::Server::u2fclib_init( $config{debug} );
        if ( !$rc ) {
            $errstr = Crypt::U2F::Server::u2fclib_getError();
            return;
        }
    }
    $refCount++;

    my $ctx = Crypt::U2F::Server::u2fclib_get_context();
    if ( !defined($ctx) || !$ctx ) {
        $errstr = Crypt::U2F::Server::u2fclib_getError();
        return;
    }
    $self->{ctx} = $ctx;

    {
        my $rc =
          Crypt::U2F::Server::u2fclib_setAppID( $self->{ctx}, $self->{appId} );
        if ( !$rc ) {
            $errstr = Crypt::U2F::Server::u2fclib_getError();
            return;
        }
    }

    {
        my $rc = Crypt::U2F::Server::u2fclib_setOrigin( $self->{ctx},
            $self->{origin} );
        if ( !$rc ) {
            $errstr = Crypt::U2F::Server::u2fclib_getError();
            return;
        }
    }

    if ( defined( $self->{keyHandle} ) ) {
        my $rc = $self->setKeyHandle;
        if ( !$rc ) {
            $errstr = Crypt::U2F::Server::u2fclib_getError();
            return;
        }
    }

    if ( defined( $self->{publicKey} ) ) {
        my $rc = $self->setPublicKey;
        if ( !$rc ) {
            $errstr = Crypt::U2F::Server::u2fclib_getError();
            return;
        }
    }

    return $self;
}

sub lastError {
    return $errstr;
}

sub registrationChallenge {
    my ($self) = @_;

    my $rc =
      Crypt::U2F::Server::u2fclib_calcRegistrationChallenge( $self->{ctx} );
    if ( !defined($rc) || !length($rc) ) {
        $errstr = Crypt::U2F::Server::u2fclib_getError();
        return;
    }

    return $rc;
}

sub registrationVerify {
    my ( $self, $registration ) = @_;

    if ( length($registration) >= $maxStringLength ) {
        $errstr = "Registration string too long!";
        return;
    }

    ( $self->{publicKey}, $self->{keyHandle} ) =
      Crypt::U2F::Server::u2fclib_verifyRegistration( $self->{ctx},
        $registration );
    if (
        not( defined( $self->{publicKey} ) and defined( $self->{keyHandle} ) ) )
    {
        $errstr = Crypt::U2F::Server::u2fclib_getError();
        return;
    }

    return ( $self->{keyHandle}, $self->{publicKey} );
}

sub setKeyHandle {
    my ( $self, $keyHandle ) = @_;

    if ( !defined($keyHandle) && !defined( $self->{keyHandle} ) ) {
        $errstr = "No keyHandle given!";
        return 0;
    }
    if ( defined($keyHandle) ) {
        $self->{keyHandle} = $keyHandle;
    }

    if ( length( $self->{keyHandle} ) >= $maxStringLength ) {
        $errstr = "keyHandle string too long!";
        return 0;
    }

    my $rc = Crypt::U2F::Server::u2fclib_setKeyHandle( $self->{ctx},
        $self->{keyHandle} );
    if ( !defined($rc) || !$rc ) {
        $errstr = Crypt::U2F::Server::u2fclib_getError();
        return;
    }

    return 1;
}

sub setPublicKey {
    my ( $self, $publicKey ) = @_;

    if ( !defined($publicKey) && !defined( $self->{publicKey} ) ) {
        $errstr = "No publicKey given!";
        return 0;
    }
    if ( defined($publicKey) ) {
        $self->{publicKey} = $publicKey;
    }

    if ( length( $self->{publicKey} ) >= $maxStringLength ) {
        $errstr = "publicKey string too long!";
        return 0;
    }

    my $rc = Crypt::U2F::Server::u2fclib_setPublicKey( $self->{ctx},
        $self->{publicKey} );
    if ( !defined($rc) || !$rc ) {
        $errstr = Crypt::U2F::Server::u2fclib_getError();
        return;
    }

    return 1;
}

sub setChallenge {
    my ( $self, $challenge ) = @_;

    if ( !defined($challenge) && !defined( $self->{challenge} ) ) {
        $errstr = "No challenge given!";
        return 0;
    }
    if ( defined($challenge) ) {
        $self->{challenge} = $challenge;
    }

    if ( length( $self->{challenge} ) >= $maxStringLength ) {
        $errstr = "challenge string too long!";
        return 0;
    }

    my $rc = Crypt::U2F::Server::u2fclib_setChallenge( $self->{ctx},
        $self->{challenge} );
    if ( !defined($rc) || !$rc ) {
        $errstr = Crypt::U2F::Server::u2fclib_getError();
        return;
    }

    return 1;
}

sub authenticationChallenge {
    my ($self) = @_;

    if ( !$self->setKeyHandle || !$self->setPublicKey ) {
        return;
    }

    my $rc =
      Crypt::U2F::Server::u2fclib_calcAuthenticationChallenge( $self->{ctx} );
    if ( !defined($rc) || !length($rc) ) {
        $errstr = Crypt::U2F::Server::u2fclib_getError();
        return;
    }

    return $rc;
}

sub authenticationVerify {
    my ( $self, $authentication ) = @_;

    if ( !$self->setKeyHandle || !$self->setPublicKey ) {
        return 0;
    }

    my $rc = Crypt::U2F::Server::u2fclib_verifyAuthentication( $self->{ctx},
        $authentication );
    if ( !defined($rc) || !$rc ) {
        $errstr = Crypt::U2F::Server::u2fclib_getError();
        return 0;
    }

    return $rc;
}

sub DESTROY {
    my ($self) = @_;

    Crypt::U2F::Server::u2fclib_free_context( $self->{ctx} );

    $refCount--;
    if ( $refCount < 0 ) {
        croak("refCount error! Aborting everything!");
    }

    if ( !$refCount ) {
        Crypt::U2F::Server::u2fclib_deInit();
    }

    return;
}

1;
__END__

=head1 NAME

Crypt::U2F::Server::Simple - Register and Authenticate U2F compatible security devices

=head1 SYNOPSIS

  use Crypt::U2F::Server:Simple;
  
  my $crypter = Crypt::U2F::Server::Simple->new(
      appId  => 'Perl',
      origin => 'http://search.cpan.org'
  );
  
  # Generate a registration request
  my $registerRequest = $crypter->registrationChallenge();
  
  # Give $registerRequest to client, receive $registrationData from client
  # NB: if Crypt::U2F::Server::Simple has been recreated (web process for example), challenge
  #     value must be restored (value only, not JSON blob):
  #$crypter->setChallenge($challenge)
  my ($keyHandle, $userKey) = $crypter->registrationVerify($registrationData)
  
  # Generate an authentication request (using the previously generated key handle and user key)
  my $authrequest = $crypter->authenticationChallenge();
  
  # Send $authrequest to client, receive $authSignature
  # NB: if Crypt::U2F::Server::Simple has been recreated (web process for example), challenge
  #     value must be restored (value only, not JSON blob):
  #$crypter->setChallenge($challenge)
  my $authok = $crypter->authenticationVerify($authSignature);

=head1 DESCRIPTION

This module implements the server side of U2F authentication through Yubico's C library.

Both registration and authentication are two step processes that each must be run in the same instance
of this perl module. To clarify You can run registration from another instance than authentication, or even
in another program on another server. But, as far as it is currently implemented, you must run both registration
steps in the same instance of this module, the same goes for authentication. Needs more testing, really.

A successful registration of a key yields to two scalars, a key handle and a public key. It is B<your>
responsibility to keep them safe somewhere and reload them into this module whenever you want to do
authentication.

=head1 INSTALLATION

This module requires the Yubico u2f-server shared library installed, please see the official
project page at L<https://developers.yubico.com/libu2f-server/> on how to do that.

=head1 NO MULTITHREADING

The way this is currently implemented, i doubt very much that multithreadingm will work.
Multi-Forking should be OK as long as you only call new() B<after> forking, though. Also
using more than one instance of this module in your program. This isn't really tested
at the moment, though...

=head1 ALPHA WARNING

As already stated above, at this time L<Crypt::U2F::Server> and L<Crypt::U2F::Server::Simple> have seen only
very limited testing and the modules are still subject to change.

That isn't to say that you shouldn't use this at all. Rather, if you are interested, you should test this
a lot and report any bugs you find!

=head1 FUNCTION DESCRIPTION

=head2 lastError()

Probably the most important function of all, therefore mention first. If something goes wrong
(but not HorriblyWrong[tm]), you'll get the last error description of whatever happened.

If something fails during new(), call it with the full name:

    my $oooops = Crypt::U2F::Server::Simple::lastError();

If you already got an instance, you can use that as well:

    my $oooops = $auth->lastError();

Errors are global over all instances of this module.

If things go HorriblyWrong[tm], your program might crash. Or get remote-buffer-overflow-exploited
or something. In these case, lastError() might not work reliably. You know, just the usual crypto
stuff...

=head2 new()

This comes in two forms, depending if you do authentication in the same instance as the registration steps.

The simple form (only registration or registration+authentication) only requires the arguments appId and origin:

    my $auth = Crypt::U2F::Server::Simple->new(
        appId  => 'Perl',
        origin => 'http://search.cpan.org'
    );

If you only do authentication, you have to supply the keyHandle and publicKey data as well:


    my $auth = Crypt::U2F::Server::Simple->new(
        appId     => 'Perl',
        origin    => 'http://search.cpan.org',
        keyHandle => $keyHandleData
        publicKey => $publicKeyData
    );

For security, i would recommend creating a new instance for each and every authentication request.

If something goes wrong during initialization, $auth will be I<undef>.

To enable Yubico library debug, set debug to 1:

    my $auth = Crypt::U2F::Server::Simple->new(
        appId  => 'Perl',
        origin => 'http://search.cpan.org',
        debug  => 1
    );

=head2 registrationChallenge()

    my $challenge = $auth->registrationChallenge();

Gives you a unique registration challenge on every call. This is a JSON string and should be send to the client
(called a "host" for whatever reason) as is.

If something goes wrong, $challenge will be I<undef>.

$challenge is a JSON blob that contains a hash. Here are the main keys

=over

=item version: the protocol version

=item appId: the appId given in new()

=item challenge: the challenge value

=back

=head2 registrationVerify()

    my ($keyHandle, $publicKey) = $auth->registrationVerify($reply);

If the client (the "host") accepts the challenge, it will send you another JSON blob ($reply).

If everything goes well and registration succeeds, you will get the key handle and public key of, well
client key. If it fails, you will get I<undef>.

$keyHandle and $publicKey will get set internally for direct following authentication in the same instance,
you need to store it in some persistent way yourself for future authentication.

As an added bonus, $publicKey will be a binary blob, so you may have to convert it to something like Base64 for
easier handling. See L<MIME::Base64> on how to do that. Make sure you un-encode before loading it into this
module!

=head2 authenticationChallenge()

This function generates an authentication challenge. To do that, it needs keyHandle and publicKey, since this
is key dependent.

    my $challenge = $auth->authenticationChallenge();

Otherwise, this works the same as the registration challenge. You get a JSON blob, send that to the client and
get an answer.

The JSON blob structure is described in registrationChallenge() doc.

=head2 authenticationVerify()

After you get the authentication answer, you need to verify it:

    my $isValid = $auth->authenticationVerify($reply);

$isValid is true if authentication succeedsr. If something went wrong (library error, fake user), $isValid is false, in which
case you can look into lastError() to see what went wrong.

=head2 setChallenge()

If Crypt::U2F::Server::Simple has been recreated since registrationChallenge()
or authenticationChallenge() usage, challenge value must be restored:

    $auth->setChallenge($challenge)

Note that $challenge must be the string value of challenge, not the JSON blob.
See registrationChallenge() doc to get challenge description.

=head1 SEE ALSO

See L<Crypt::U2F::Server> for the low level library if you want better headaches.

There are two examples in the tarball for registration and authentication.

=head1 BUGS

Yes, there should be some in there. First of all, this is crypto stuff, so
it's broken by default (it only depends on the time it takes to happen).

Also, at the moment, this module has seen only very limited testing.

=head1 AUTHOR

=over

=item Rene Schickbauer, E<lt>rene.schickbauer@magnapowertrain.comE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Adapted as a Perl library by Rene 'cavac' Schickbauer

This roughly based on u2f-server.c from Yubico's
C library, see L<https://developers.yubico.com/libu2f-server/>

In order for this to work, you need to install that
library.

This adaption is (C) 2014-2018 Rene 'cavac' Schickbauer and 2018 Xavier
Guimard, but as it is based on Yubico's code, the licence below applies!

I<We, the community, would hereby thank Yubico for open sourcing their code!>

    /*
    * Copyright (c) 2014 Yubico AB
    * All rights reserved.
    *
    * Redistribution and use in source and binary forms, with or without
    * modification, are permitted provided that the following conditions are
    * met:
    *
    * * Redistributions of source code must retain the above copyright
    * notice, this list of conditions and the following disclaimer.
    *
    * * Redistributions in binary form must reproduce the above
    * copyright notice, this list of conditions and the following
    * disclaimer in the documentation and/or other materials provided
    * with the distribution.
    *
    * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
    */

=cut
