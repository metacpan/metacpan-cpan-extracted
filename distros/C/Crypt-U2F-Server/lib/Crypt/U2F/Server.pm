package Crypt::U2F::Server;

use 5.018001;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA     = qw(Exporter);
our $VERSION = '0.47';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Crypt::U2F ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
          u2fclib_calcAuthenticationChallenge
          u2fclib_calcRegistrationChallenge
          u2fclib_deInit
          u2fclib_free_context
          u2fclib_getError
          u2fclib_get_context
          u2fclib_init
          u2fclib_setAppID
          u2fclib_setChallenge
          u2fclib_setKeyHandle
          u2fclib_setOrigin
          u2fclib_setPublicKey
          u2fclib_verifyAuthentication
          u2fclib_verifyRegistration
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

sub AUTOLOAD {

    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ( $constname = $AUTOLOAD ) =~ s/.*:://;
    croak "&Crypt::U2F::Server::constant not defined"
      if $constname eq 'constant';
    my ( $error, $val ) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load( 'Crypt::U2F::Server', $VERSION );

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Crypt::U2F::Server - Low level wrapper around the U2F two factor authentication C library (server side)

=head1 SYNOPSIS

  use Crypt::U2F::Server;

=head1 DESCRIPTION

This is a very low level wrapper around the original C library. You probably B<shouldn't> use it,
but use L<Crypt::U2F::Server::Simple> instead!

This API is subject to change, depending on the underlying library, the weather and the whims of
the developer.

If you decide to use it anyway, it would probably be a good idea to specify the exact version number
of L<Crypt::U2F::Server> to use.

=head1 INSTALLATION

This module requires the Yubico u2f-server shared library installed, please see the official
project page at L<https://developers.yubico.com/libu2f-server/> on how to do that.

=head1 NO MULTITHREADING / MULTI INSTANCES

The way this is currently implemented, i doubt very much that multithreading or even use in
more than one instance in your program will work. Multi-Forking should be OK, though, if you
only call u2fclib_init() after forking, but this isn't tested as of yet.

The problem is how u2fclib_init() and u2fclib_deInit() are implemented. While the underlying
library has a context-handle (not used here), u2fclib_deInit() will tear down everything as far
as i can tell.

L<Crypt::U2F::Server::Simple> works around this problem by reference counting and always requiring all
values to call the relevant u2fclib_set* functions.

=head2 EXPORT

None by default.

=head2 Exportable functions


  char* u2fclib_calcRegistrationChallenge(void* ctx)
  int u2fclib_deInit(void)
  int u2fclib_free_context(void* ctx)
  char* u2fclib_getError(void)
  void* u2fclib_get_context(void)
  int u2fclib_init(bool debug)
  int u2fclib_setAppID(void* ctx, char* appid)
  int u2fclib_setChallenge(void* ctx, char* challenge)
  int u2fclib_setKeyHandle(void* ctx, char* buf)
  int u2fclib_setOrigin(void* ctx, char* origin)
  int u2fclib_setPublicKey(void* ctx, char* buf)
  int u2fclib_verifyAuthentication(void* ctx, char* buf)
  registrationData_t* u2fclib_verifyRegistration(void* ctx, char* buf)



=head1 SEE ALSO

See L<Crypt::U2F::Server::Simple> for the module you should actually be using.

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
