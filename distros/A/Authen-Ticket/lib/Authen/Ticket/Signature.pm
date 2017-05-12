# $Id: Signature.pm,v 1.9 1999/11/16 19:36:35 jgsmith Exp $
#
# Copyright (c) 1999, Texas A&M University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTERS ``AS IS''
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package Authen::Ticket::Signature;

use strict;
use OpenSSL;

use vars (qw/$VERSION %DEFAULTS @ISA %Keys/);

@ISA = ( );
$VERSION = '0.02';

%DEFAULTS = (
  TicketSignatureKeyLength => 512,
  TicketSignaturePublicKey => undef,
  TicketSignatureId        => 'General',
);

sub tie_keys {
  unless(tied %Keys or not defined $IPC::Shareable::VERSION) {
    tie(%Keys, 'IPC::Shareable', 'dkfj', {  # random glue...
                                mode => 0600,  # a bit more secure
                                destroy => 'no',
                                exclusive => 'no',
                                create => 'yes',
                              });
  }
}

if(defined $Apache::VERSION) {
  Apache->push_handlers(PerlChildInitHandler => \&tie_keys);
}

# following should be called to retrieve stored public key
sub get_public_key {
  my $self = shift;

#  tie_keys;

  my $id = shift || $self->{TicketSignatureId} || '<none>';

  $self->debug("\%Keys is tied") if tied %Keys;

  $self->debug("Using public key $id");

  return { %{$Keys{$id}->{Public}} } if(exists $Keys{$id} and
                                        defined $Keys{$id}->{Public});

  return '' unless $self->{TicketSignaturePublicKey};

  my $loc = $self->{TicketSignaturePublicKey};

  $loc =~ s{\$\{id\}}{$id};
  my $key;
  if($loc =~ /^http:/) {
    $key = LWP::Simple::get($loc);
  } elsif($self->{TicketSignaturePublicKey}) {
    my $fh = Apache::File->new($loc) || return '';
    $key = <%fh>;
  }
  chomp($key);
  if($key) {
    my %parts = {(map split(/:/), split(/;/, $key))};
    $Keys{$id}->{Public} = { %parts };
    return { %{$Keys{$id}->{Public}} };
  }

  return '';
}

# called to either retrieve stored private key or generate public/private
# pair
sub get_private_key {
  my $self = shift;

#  tie_keys;

  my $id = $self->{TicketSignatureId} || '<none>';
  
  if(exists $Keys{$id} and defined $Keys{$id}->{Private}) {
    my $hprivate = $Keys{$id}->{Private};
    my $private = { map(($_ => OpenSSL::BN::hex2bn($hprivate->{$_})),
                      keys %$hprivate) };
    return $private;
  }

  my($private, $public) = 
       $self->generate_key($self->{TicketSignatureKeyLength});

  my $hprivate = { map(($_ => OpenSSL::BN::bn2hex($private->{$_})),
                        keys %$private) };

  my $hpublic  = { map(($_ => OpenSSL::BN::bn2hex($public ->{$_})),
                        keys %$public ) };


  $Keys{$id} = { Private => $hprivate, Public => $hpublic };


  return $private;
}

#
# key generation for El Gamal
#
sub generate_key {
  my($self, $key_length) = @_;

  my($p, $g, $x, $y);

  $p = OpenSSL::BN::generate_prime( $key_length || 512, 0 );
  $g = OpenSSL::BN::rand( $p->num_bits - 1 );
  $x = OpenSSL::BN::rand( $p->num_bits - 1 );
  $y = $g->mod_exp( $x, $p );

  return ( { 'x' => $x, p => $p, g => $g },
           { 'y' => $y, p => $p, g => $g } );
}

sub sign_ticket {
  my($self, $ticket) = @_;

  my $private_key = $self->get_private_key;

  return '' unless $private_key;

  my($p, $g, $x) = map $private_key->{$_}, (qw/p g x/);
  my $msg = OpenSSL::BN::hex2bn(MD5->hexhash($ticket));

  my $k;
  do { $k = OpenSSL::BN::rand( $p->num_bits - 1);
  } until $k->gcd( $p - 1 ) == 1;

  my $a = $g->mod_exp( $k, $p );
  my $b = $p - 1 + $msg - $x->mod_mul( $a, $p-1 );
  $b = $b->mod_mul( OpenSSL::BN::mod_inverse( $k, $p-1 ), $p-1 );

  return join(':', $a->bn2hex, $b->bn2hex, $ticket);
}

sub verify_ticket {
  my($self, $ticket) = @_;

  my $public_key = $self->get_public_key;

  $self->debug("Public Key: [$public_key]");
  $self->debug("Key values:", join(",", keys %$public_key));

  return '' unless $public_key;

  my($a, $b, $omsg) = split(/:/, $ticket, 3);

  return '' unless $a && $b;

  my $msg = OpenSSL::BN::hex2bn(MD5->hexhash($omsg));

  $a = OpenSSL::BN::hex2bn($a);
  $b = OpenSSL::BN::hex2bn($b);

  my($y, $p, $g) = map OpenSSL::BN::hex2bn($public_key->{$_}), (qw/y p g/);
  #my($y, $p, $g) = map $public_key->{$_}, (qw/y p g/);
  $self->debug("y -> $y");
  $self->debug("p -> $p");
  $self->debug("g -> $g");
  $self->debug("a -> $a");
  $self->debug("b -> $b");

  my $lhs = $a->mod_exp( $b, $p );
  $self->debug("lhs -> $lhs");
  $lhs = $y->mod_exp( $a, $p)->mod_mul( $lhs, $p );
  $self->debug("lhs -> $lhs");
  my $rhs = $g->mod_exp( $msg, $p );
  $self->debug("rhs -> $rhs");

  return $omsg if $lhs == $rhs;
  return '';
}

sub debug {
  my $self = shift;

  if($$self{_log}) {
    $$self{_log}->debug(join($,,@_));
  }
}

sub handler ($$) {
  my($class, $r) = @_;

  my $self = { };

  bless $self, $class;

  $self->{_log} = $r->log;

  foreach my $k (qw/PublicKey Id/) {
    if($r->dir_config("TicketSignature$k")) {
      $self->{"TicketSignature$k"} = 
        $r->dir_config("TicketSignature$k");
    }
  }

  $self->debug("Available keys: <", join('><', keys %Keys), ">");

  my $id = $r->path_info;

  $id =~ s{^/+}{};

  $self->debug("Id: [$id]");

  my $keys = $self->get_public_key($id);

  return Apache::Constants->NOT_FOUND unless $keys;

  $r->content_type('text/plain');

  my @pk;
  $keys = { %{$keys} };

  $self->debug("Keys available are: <", join("><", keys %$keys), ">");

  foreach my $k (keys %$keys) {
    my $v = $keys->{$k};
    my $h = OpenSSL::BN::bn2hex($v);

    push @pk, "$k:$h";
  }

  $r->send_http_header;

  $r->print(join(';', @pk));

  return Apache::Constants->OK;
}

1;
__END__

=pod
=head1 NAME

Authen::Ticket::Signature - Support for signing authentication tickets

=head1 SYNOPSIS

As key server:

  <Location "/keys">
    SetHandler perl-script
    PerlSetHandler Authen::Ticket::Signature
    PerlSetVar  TicketSignaturePublicKey http://keys.my.com/keys/${id}
    PerlSetVar  TicketSignatureId        General
  </Location>

As part of ticket server:

  package My::Ticket::Server;

  @ISA = (qw/Authen::Ticket::Server Authen::Ticket::Signature/);

As part of ticket client:

  package My::Ticket::Client;

  @ISA = (qw/Authen::Ticket::Client Authen::Ticket::Signature/);

=head1 DESCRIPTION

Authen::Ticket::Signature provides the framework for signing and verifying
tickets.  The El Gamal algorithm is included in the code as a good default
signing algorithm.  The default key length is 512 bits.

If IPC::Shareable is available, keys are cached in shared memory across
processes.  This is a virtual requirement for a multiprocess Apache
ticket server since all tickets should be signed by the same key.  This
is only a memory issue for client websites if several keys might need to
be cached simultaneously.

Different keys may be cached with each having an identifying name.  This
name is used to retrieve the public portion of the key from the key server.
The key to be retrieved for use in signing or verification is determined
by the server configuration.

=head1 METHODS

Adding Authen::Ticket::Signature to the @ISA array for the ::Client or
::Server class will add the following methods to that class.  Any may be
overridden, though only generate_key, sign_ticket, and verify_ticket
are recommended.  All numbers are expected to be objects of type
OpenSSL::BN.

=over 4

=item handler

This routine provides the key server functionality.  Only public keys
may be requested.  The path-info part of the request is the name of a
key.  For example, if http://my.com/keys is the location of the key
server, then http://my.com/keys/general will return the public key of
the default key for signing tickets.

=item $self->get_public_key

This routine will return the public key as appropriate according to the
server configuration.  If the key is not available in memory, an attempt
will be made to fetch the key either from a remote server or the file
system.  

A public key is a hash reference with the various
parts of the key.  This is algorithm dependent.  The El Gamal routine
will return the following hashref:

  { 'y' => $y, 'p' => $p, 'g' => $g }

This is returned by the key server as the string "y:$y;p:$p;g:$g" with
the values in hexadecimal.

=item $self->get_private_key

This routine will return the private key as appropriate according to the
server configuration.  If the required key is not available in cache, it
will be generated.  Since the private key is only to be used on the machine
it is generated on, it does not make sense to fetch the private key from
any particular location.  

A private key is a hash reference with the various parts of the key.  This
is algorithm dependent.  The El Gamal routine will return the following
hashref:

  { 'x' => $x, 'p' => $p, 'g' => $g }

=item $self->generate_key( $key_length )

This routine must return the private and public key parts with a nominal
key length of $key_length.  See the get_{private,public}_key routines
for the format of the key parts.  The actual value returned is an array
of the format:

  ( { private_key }, { public_key } )

=item $self->sign_ticket( $ticket )

This routine should attach a signature to $ticket and return the resulting
value.  The format used must be understood by $self->verify_ticket.  The
$ticket will have already been passed through $self->construct_ticket
and $self->encode_ticket.

=item $self->verify_ticket( $ticket )

This routine should verify the signature on the $ticket and return the
encoded ticket without the signature (this would be the value that was
passed to sign_ticket).  The following must hold true:

  $self->verify_ticket($self->sign_ticket($ticket)) eq $ticket

=head1 WHY EL GAMAL?

This code was produced and is maintained within the United States of
America.  As many are aware, export restrictions on cryptographic
products exist.  This section explains what algorithm was chosen and
why it should not violate any export regulations.

The El Gamal algorithms are not under any patent or licensing
restrictions and may thus be used freely, though with export
restrictions in mind.

The default algorithm in Authen::Ticket::Signature is El Gamal.  The
supplied code IS NOT INTENDED to be used to encrypt messages.  
Other parts of the
algorithm may be used for encryption, but the signature portions are
not intended to encrypt and decrypt data.  
However, [Schneier 532] points out the ability to send subliminal
messages using the signature algorithms.

=head1 SHARED MEMORY

The code tries to use IPC::Shareable if it is already loaded.  
Apache can go into an endless spin with children being dieing and
being created if the IPC::Shareable code causes a segfault during
child initialization.  This can happen when a previously created
shared memory segment has not been properly disposed of and also
cannot be connected to.

If IPC::Shareable is not loaded during the server startup, the
Authen::Ticket::Signature code will not try to use it.  Therefore,
you must load IPC::Shareable before loading Authen::Ticket::Signature
or any class derived from it.

=head1 AUTHOR

James G. Smith, <jgsmith@tamu.edu>

Portions of code are based on [Orwant 552-554] and [Stein 320].

=head1 COPYRIGHT

Copyright (c) 1999, Texas A&M University.  All rights reserved.  

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above
    copyright notice, this list of conditions and the following
    disclaimer in the documentation and/or other materials
    provided with the distribution.
 3. Neither the name of the University nor the names of its
    contributors may be used to endorse or promote products
    derived from this software without specific prior written
    permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTERS ``AS IS''
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

=head1 SEE ALSO

perl(1), Authen::Ticket(3), Authen::Ticket::Server(3),
Authen::Ticket::Client(3)

Orwant, Jon, et. al. I<Mastering Agorithms with Perl>, O'Reilly & Associates,
1999.

Schneier, Bruce I<Applied Cryptography>, 2nd ed., John Wiley & Sons, 1996.

Stein, Lincoln, & Doug MacEachern. I<Writing Apache Modules with Perl and C>,
O'Reilly & Associates, 1999.

=cut
