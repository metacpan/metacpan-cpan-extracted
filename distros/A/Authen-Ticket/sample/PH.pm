# $Id: PH.pm,v 1.1 1999/11/11 03:28:32 jgsmith Exp $
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

#
# Sample derivation from Authen::Ticket using the CCSO Nameserver
#

#
# Put the following in the httpd.conf file:
#
# For client website:
#
#    PerlAccessHandler My::PH
#    PerlSetVar        TM_Domain .tamu.edu
#    ErrorDocument     403 http://ticket.tamu.edu/
#
# For server website:
#
#    PerlHandler My::PH
#

use strict;

#
# main switch class
#

package My::PH;

use vars (qw/@ISA $VERSION/);

$VERSION = '0.01';
@ISA = (qw/Authen::Ticket/);

#
# ticket server class
#

package My::PH::Server;

use vars (qw/@ISA $VERSION %DEFAULTS/);

use Net::PH ();

$VERSION = '0.01';
@ISA = (qw/Authen::Ticket::Server/);
#@ISA = (qw/Authen::Ticket::Server Authen::Ticket::Signature/);
%DEFAULTS = (
  TicketNameserver     => 'ns.tamu.edu',
  TicketNameserverPort => '105',
};

sub authenticate {
  my($class, $r, $u) = @_;

  my $ph = new Net::PH($self->{TicketNameserver}, 
                       $self->{TicketNameserverPort});

  if($ph->login($u->{user}, $u->{password}, 1)) {
    $ph->logout;
    return { };
  }
  return undef;
}

#
# ticket client class
#

package My::PH::Client;

use vars (qw/@ISA $VERSION/);

$VERSION = '0.01';
@ISA = (qw/Authen::Ticket::Client/);
#@ISA = (qw/Authen::Ticket::Client Authen::Ticket::Signature/);

1;
