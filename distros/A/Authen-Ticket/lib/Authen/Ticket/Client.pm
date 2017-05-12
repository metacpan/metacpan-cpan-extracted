# $Id: Client.pm,v 1.7 1999/11/18 21:11:41 jgsmith Exp $
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

package Authen::Ticket::Client;

use strict;

use vars (qw/$VERSION %DEFAULTS @ISA/);

use MIME::Base64 (qw/decode_base64/);

use Carp;

if($ENV{MOD_PERL}) {
  @ISA = (qw/Apache/);
} else {
  @ISA = ( );
}

$VERSION = '0.02';

%DEFAULTS = (
  TicketDomain => undef,
  TicketName   => 'ticket',
);

sub debug {
  my $self = shift;

  if($$self{_log}) {
    $$self{_log}->debug(join($,,@_));
  } elsif($$self{DEBUG}) {
    carp join($,,@_);
  }
}

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my $r;
  my $self = { };
  my $cookies;

  bless $self, $class;

  if($ENV{MOD_PERL}) {
    $r = shift;
    unless(ref $r) {
      unshift @_, $r;
      $r = '';
    }
    $r ||= Apache->request;
    $self->{_r} = $r;
    $self->{_log} = $r->log;
    $cookies = $r->headers_in->{Cookie};
  } else {
    $cookies = $ENV{HTTP_COOKIE};
  }

  my @cookies = split(/;\s*/, $cookies);

  $self->configure(@_);

  $self->initialize;

  $self->debug("Getting ticket: $$self{TicketName}");
  my $ticket;
  my $ticket_name = $$self{TicketName};

  while(@cookies && !$ticket) {
    my $t = shift @cookies;
    $self->debug("Considering [$t]");
    my($k, $v) = split(/=/, $t, 2);
    $k =~ s{%(..)}{chr(hex($1))}ge;
    $self->debug("$k => [$v]");
    next unless $k eq $$self{TicketName};
    $v =~ s{%(..)}{chr(hex($1))}ge;
    $ticket = $v;
  }

  $self->debug("Cookies: [$cookies]");
  $self->debug("Ticket: [$ticket]");
  
  #
  # provide automatic signature verification if available...
  #
  $self->debug("Ticket: [$ticket]");
  my $sc = eval { $self->verify_ticket($ticket); };
  if($@) {
    $self->debug("Eval results: [$@]");
  } else {
    $ticket = $sc;
    $self->debug("Verified ticket: [$sc]");
  }
  $self->debug("Ticket now: [$ticket]");

  $self->{ticket} = $self->deconstruct_cookie(
                      $self->decode_cookie(
                        ref($ticket) ? join('', @{ $ticket })
                                     : $ticket
                      )
                    );

  return $self
}

sub configure {
  my $self = shift;
  my %opts = (@_);

  # build options hash
  my %defaults = ( );
  my @classes = ( );
  my %classes_seen = ( );

  push @classes, (ref $self or $self);

  while(@classes) {
    no strict;
    my $class = shift @classes;
    next if $classes_seen{$class};
    $classes_seen{$class}++;
    push @classes, @{ "$class\::ISA" };
 

    if(defined %{ "$class\::DEFAULTS" }) {
      foreach my $k ( keys %{ "$class\::DEFAULTS" } ) {
        $defaults{$k} ||= ${ "$class\::DEFAULTS" }{$k};
      }
    } 
  } 
  
  if($$self{_r}) {
    foreach my $k (keys %defaults) {
      $self->{$k} = $self->dir_config($k);
    }
 
    unless($self->{TicketDomain}) {
      $$self{TicketDomain} = $self->server->server_hostname;
      $$self{TicketDomain} =~ s/^[^.]+//;
    }
  }
 
  foreach my $k (keys %defaults) {
    $$self{$k} ||= $opts{$k} || $defaults{$k};
    $self->debug("$k set to $$self{$k}");
  }
}

sub initialize { }

sub decode_cookie {
  my($self, $ticket) = @_;

  return decode_base64($ticket);
}

sub deconstruct_cookie {
  my($self, $ticket) = @_;

  my $t = { };

  $self->debug("Ticket: [$ticket]");

  $ticket .= ',';
  my @parts = $ticket =~ m{((.*?)                 # keyword match
                            \s*=\s*               #
                            (("(.*?)",)|((.*?),)) # value match
                            )
                           }gx
                             ;
  @parts = grep(!/^\s*$/, @parts);
    foreach my $i (0..(@parts/5)) {
        # tag = 1 mod 5
        # value = 4 mod 5
        $t->{$parts[$i*5+1]} = $parts[$i*5+4];
    }

  return $t;
}

1;
__END__
=pod

=head1 NAME

Authen::Ticket::Client - Authentication code for the client website

=head1 DESCRIPTION

Authen::Ticket::Client contains the basic tools required to decode and
reconstruct the information in a ticket.  See Authen::Ticket for the
mod_perl access handler using Authen::Ticket::Client.

=head1 METHODS

=over 4

=item decode_cookie($class, $ticket)

This subroutine returns the decoded version of the ticket.  This is the
place to put decryption of the cookie or other checks that do not
depend on understanding the information within the ticket.  The default
version decodes from base 64.  The return value is the decoded
string representation of the ticket.

=item deconstruct_cookie($class, $ticket)

This subroutine breaks the ticket apart into field values.  The return
value is a hash reference containing the key/value pairs.  This subroutine
should only be concerned with ensuring a properly constructed ticket.

=item initialize()

This subroutine may be used to perform particular class initialization
beyond the defaults provided by Ticket::Authen::Client->new.  Any
configuration variables for the httpd configuration file should be
placed in the %__PACKAGE__::DEFAULTS hash.

=head1 AUTHOR

James G. Smith, <jgsmith@tamu.edu>

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

perl(1), Authen::Ticket(3), Authen::Ticket::Server(3)

=cut
