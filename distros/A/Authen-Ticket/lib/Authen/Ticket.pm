# $Id: Ticket.pm,v 1.8 1999/11/18 21:22:32 jgsmith Exp $
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

package Authen::Ticket;

use Apache ();
use Apache::Constants (qw/OK DECLINED FORBIDDEN/);
use Apache::URI ();
use CGI::Cookie ();

use vars (qw#$VERSION @ISA#);

$VERSION = '0.02';
@ISA = ( );

sub handler ($$) {
  my $class = shift;
  my $r = shift;
  my $log = $r->log;

  Apache->request($r);  # set it to make sure it is set...

  $log->debug("Callback: " . $r->current_callback);

  if($r->current_callback eq "PerlHandler" ||
     $r->current_callback eq "PerlFixupHandler") {
    my $cclass = "$class\:\:Client";
    $class .= "::Server";
    my $self = $class->new($r);

    my $ticketinfo;

    unless($self->{request_uri}) {
      $self->no_cookie_error;
      return OK;
    }

    my $userinfo = $self->get_userinfo;

    unless($$userinfo{user} || $$userinfo{security}) {
      my $client = $cclass->new($r);
      if($client->{ticket}) {
        $userinfo->{security} = 'strong';
        if($client->{ticket}->{ip}) {
          my(@bip) = split('.', $client->{ticket}->{ip});
 
          if(($bip[0] < 128 && !($bip[1] || $bip[2] || $bip[3]))
           ||($bip[0] < 192 && !(           $bip[2] || $bip[3]))
           ||($bip[0] < 224 && !(                      $bip[3])))
            { $userinfo->{security} = 'med'; }
        } else {
          $userinfo->{security} = 'weak';
        }
        $userinfo->{user} = $client->{ticket}->{uid};
      }
    }

    unless($$userinfo{user} && $$userinfo{password}) {
      $self->no_user_password_error;
      return OK;
    }

    unless($$userinfo{duration} > 0) {
      $self->no_user_password_error(
          "Duration must be a number greater than zero."
      );
      return OK;
    }

    unless($ticketinfo = $self->authenticate($userinfo)) {
      $self->no_user_password_error(
          "Either the username or password are incorrect."
      );
      return OK;
    }

    $ticketinfo->{fields} = join(',',keys %$ticketinfo);
    $ticketinfo->{uid}  = $$userinfo{user};

    if($userinfo->{security} ne 'weak') {
      my $ip = $self->connection->remote_ip;
      my(@rip) = ($ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/);
      if($userinfo->{security} eq 'med') {
        if($rip[0] < 128)    { $rip[1] = $rip[2] = $rip[3] = 0; }
        elsif($rip[0] < 192) {           $rip[2] = $rip[3] = 0; }
        elsif($rip[0] < 224) {                     $rip[3] = 0; }
      }
      $$ticketinfo{ip} = join('.', @rip);
    }

    my $cookiev = $self->encode_cookie(
                    $self->construct_cookie(%$ticketinfo,
                             'expiry' => time + $$userinfo{duration} * 60) );

    #
    # sign ticket if signing is available...
    #
    my $sc = eval { $self->sign_ticket($cookiev); };
    if($@) {
      $self->debug("Eval results: [$@]");
    } else {
      $cookiev = $sc;
    }
    
    $self->go_to_url(CGI::Cookie->new(-name => $$self{TicketName},
                                      -value => $cookiev,
                                      -domain => $$self{TicketDomain},
                                      -path => '/'
                                     ));
    return OK;
  } elsif($r->current_callback eq "PerlAccessHandler") {
    $class .= "::Client";

    return OK unless $r->is_main;

    my $checkedout = 1;

    # we want to be able to include the ticket as part of the URL if needed
    # this needs to work even with a POST...

    my $self = $class->new($r);
 
    unless($self->{ticket} && $self->{ticket}->{expiry} > time) {
      # bad ticket... need another
      $checkedout = 0;
      $log->debug("No ticket or ticket expired...");
    }

    if($self->{ticket} && $self->{ticket}->{ip}) {
      my(@bip) = split('.', $self->{ticket}->{ip});
      my(@rip) = split('.', $r->connection->remote_ip);
  
      if(   $bip[0] < 128 && !($bip[1] || $bip[2] || $bip[3]))
        { $rip[1] = $rip[2] = $rip[3] = 0; }
      elsif($bip[0] < 192 && !(           $bip[2] || $bip[3]))
        {           $rip[2] = $rip[3] = 0; }
      elsif($bip[0] < 224 && !(                      $bip[3]))
        {                     $rip[3] = 0; }

      for(my $i = 0; $i < 4; $i++) {
        if($bip[$i] != $rip[$i]) {
          # bad ticket... need another
          $checkedout = 0;
          $log->debug("IP addresses don't match");
          last;
        }
      }
    }

    unless($checkedout) {
      $log->debug("Ticket didn't check out");
      my $uri = Apache::URI->parse($r, $r->uri);
      $uri->scheme('http');
      $uri->hostname($r->get_server_name);
  
      $uri->port($r->get_server_port);
      $uri->query(scalar $r->args);

      $log->debug("Ticket `request_uri' being set to `" .
                  $uri->unparse . "'");

      # read in content if it exists...  even for a GET
  
      $self->err_headers_out->add('Set-Cookie' =>
        CGI::Cookie->new(-name => 'request_uri',
                         -value => $uri->unparse,
                         -domain => $self->{TicketDomain},
                         -path => '/'
                        )
        );
      return FORBIDDEN;
    }

    $r->connection->user($self->{ticket}->{uid});
    return OK;
  } else {
    return DECLINED;
  }
}

1;
=pod

=head1 NAME

Authen::Ticket - Perl extension for implementing ticket authentication

=head1 SYNOPSIS

  PerlHandler Authen::Ticket

or

  PerlAccessHandler Authen::Ticket
  ErrorDocument     403  http://ticket.tamu.edu/TicketMaster/

=head1 DESCRIPTION

Authen::Ticket provides the mod_perl framework for using the
Authen::Ticket::Server and Authen::Ticket::Client classes as
Apache handlers.

To create custom handlers, derive a class (My::Authen) from
Authen::Ticket:

  package My::Authen;
  use vars (qw/@ISA/);
  @ISA = (qw/Authen::Ticket/);

In addition to My::Authen, the server and client classes are also
required:

  package My::Authen::Server;
  use vars (qw/@ISA/);
  @ISA = (qw/Authen::Ticket::Server/);

  sub authenticate {
    my($self, $u) = @_;
    my $t = { };

    # do stuff
    return $t;   # hash ref to ticket contents
  }

  package My::Authen::Client;
  use vars (qw/@ISA/);
  @ISA = (qw/Authen::Ticket::Client/);

See the documentation for each of Authen::Ticket::Server and
Authen::Ticket::Client for a list of methods that may be
implemented.

=head1 AUTHOR

James G. Smith <jgsmith@tamu.edu>

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

perl(1), Authen::Ticket::Client(3), Authen::Ticket::Server(3).

=cut

