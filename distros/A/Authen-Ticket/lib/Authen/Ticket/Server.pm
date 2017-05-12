# $Id: Server.pm,v 1.8 1999/11/18 21:22:33 jgsmith Exp $
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

package Authen::Ticket::Server;

use strict;
use vars qw($VERSION @ISA %DEFAULTS);

use CGI ();
use MIME::Base64 (qw/encode_base64/);
use Carp;


$VERSION = '0.02';
@ISA = (qw/Apache/);

%DEFAULTS = (
  TicketExpires => 900,
  TicketDomain  => undef,
  TicketName    => 'ticket',
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

  if($ENV{MOD_PERL}) {
    $r = shift;
    unless(ref $r) {
      unshift @_, $r;
      $r = '';
    }
    $r ||= Apache->request;
    $self->{_r} = $r;
    $self->{_log} = $r->log;
    $ENV{HTTP_COOKIE} ||= $r->headers_in->{Cookie};
  }

  bless $self, $class;

  $self->{query} = $self->get_query_object;
  $self->{stdout} = $self->get_stdout_object;

  $self->{request_uri} = $$self{query}->param('request_uri');

  if($$self{_r}) {
    $self->{request_uri} ||= $self->prev && $self->prev->uri;
  }
  $self->debug("Request URI: [", $$self{request_uri}, "]");

  my $cookie = $$self{query}->cookie('request_uri');

  $self->debug("Cookie: [", $cookie, "]");

  $self->{request_uri} ||= $cookie;

  $self->{has_cookies} = 1 if $cookie;

  $self->configure(@_);

  $self->initialize;

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

sub get_query_object {
  my $self = shift;

  return $$self{query} || $CGI::DefaultClass->new;
}

sub get_stdout_object {
  my $self = shift;

  return $$self{stdout} || tied *STDOUT;
  #return $$self{stdout} || ($$self{_r} ? $self : "STDOUT");
}

sub no_cookie_error {
  my $self = shift;
  my $query = $$self{query};
  my $stdout = $$self{stdout};
  my $string = join($,, @_);

  $stdout->print(
    $query->header(),
    $self->no_cookie_error_message($string)
  );
  CGI::WeT->show_page if defined $CGI::WeT::VERSION;
}

sub no_cookie_error_message {
  my $self = shift;
  my $q = $$self{query};
  my $s = shift;

  return (
    $q->start_html(-title => 'Unable to Log In', -bgcolor => 'white'),
    $q->h1('Unable to Log In'),
    "This site uses cookies for its own security.  Your browser must ",
    "be capable of processing cookies ", $q->em('and'), " cookies must be ",
    "activated.  Please set your browser to accept cookies, then press ",
    "the ", $q->strong('reload'), " button.", $q->hr ,
    $q->end_html
  );
}

sub no_user_password_error {
  my $self = shift;
  my $query = $$self{query};
  my $stdout = $$self{stdout};
  my $request_uri = $$self{request_uri};
  my $string = join($,, @_);

  $stdout->print(
    $query->header,
    $self->no_user_password_error_message($string)
  );
  CGI::WeT->show_page if defined $CGI::WeT::VERSION;
}

sub no_user_password_error_message {
  my $self = shift;
  my $q = $$self{query};
  my $rq = $$self{request_uri};
  my $s = shift;

  my $v =
    $q->start_html(-title => 'Log In', -bgcolor => 'white') .
    $q->h1('Please Log In');
  $v .= $q->h2($q->font({color => 'red'}, "Error: $s")) if $s;
  $v .= $q->start_form(-action => $q->script_name) .
        $q->table(
          $q->Tr($q->td(['Name',     $q->textfield(-name => 'user')])),
          $q->Tr($q->td(['Password', $q->password_field(-name => 'password')])),
          $q->Tr($q->td(['Duration', $q->textfield(-name => 'duration',
                                                   -default =>
                     ($$self{TicketExpires} || 900) / 60,
                                                   -size => '4') .
                                                        ' minutes'])),
          $q->Tr($q->td(['Security', $q->popup_menu(
                           -name => 'security',
                           '-values' => [qw(strong med weak)],
                           -default => 'strong',
                           -labels => {qw(strong Strong med Medium weak Weak)},
                         ) ] ) )
        ) .
        $q->hidden(-name => 'request_uri', -value => $rq) .
        $q->submit('Log In') .
        $q->end_form . $q->em('N.B.:');
  $v .= <<1HERE1;
You must set your browser to accept cookies in order for login 
to succeed.  You will be asked to log in again after some period 
of time has elapsed.
<p>
Strong security is recommended for any browser not using a proxy.  Weak 
security is only recommended when the browser is going through different 
proxies on different networks.  Use the strongest security that will allow 
access.
</p>
1HERE1

  return $v;
}

sub get_userinfo {
  my $self = shift;
  my $q = $$self{query};

  my $u = { };

  foreach my $k (qw/user password duration security/) {
    $u->{$k} = $q->param($k);  
  }  
  
  return $u;
}

sub authenticate {
  my $self = shift;
  my $userinfo = shift;

  my $class = ref $self || $self;
  if($$self{_r}) {
    $self->log->warn("$class\->authenticate is undefined");
  } else {
    carp "$class\->authenticate is undefined";
  }

  return undef;
}

sub _quote_value {
  my $v = shift;
  $v =~ s{"}{\\"}g;
  if($v =~ /\s|[,]/) {
    return "\"$v\"";
  } else {
    return $v;
  }
}

sub construct_cookie {
  my $self = shift;
  my %ticketinfo = @_;

  return(
    join(',', map { "$_=".&_quote_value($ticketinfo{$_}) } keys %ticketinfo));
}

sub encode_cookie {
  my $self = shift;
  my $value = shift;

  return encode_base64($value,'');
}

sub go_to_url {
  my $self = shift;
  my $query = $$self{query};
  my $stdout = $$self{stdout};
  my $request_uri = $$self{request_uri};
  my $cookie = shift;

  $stdout->print(
     $query->header(-refresh => "1; URL=$request_uri", -cookie => $cookie),
     $self->go_to_url_message
  );
  CGI::WeT->show_page if defined $CGI::WeT::VERSION;
}

sub go_to_url_message {
  my $self = shift;
  my $q = $$self{query};
  my $request_uri = $$self{request_uri};

  return (
    $q->start_html(-title => 'Successfully Authenticated', -bgcolor => 'white'),
    $q->h1('Congratulations'),
    $q->h2('You have successfully authenticated'),
    "If your browser does not automatically take you to the page you ",
    "selected, <a href=\"$request_uri\">Click here</a>.",
    $q->end_html()
  );
}
  
1;
__END__
=pod

=head1 NAME

Authen::Ticket::Server - Perl extension for implementing ticket authentication.

=head1 DESCRIPTION

Authen::Ticket::Server is an abstract class which provides the skeleton upon
which a full ticket issuing master authentication server may be built.
With appropriate subroutine definitions, the resulting class may provided
authentication for either trusted or untrusted client sites.

The class may be used to implement a ticket server either as
a mod_perl handler (see Authen::Ticket) or as a CGI script 
(using the object methods).

If the server class is a sub-class of Authen::Ticket::Signature (or
comparable class), the ticket will automatically be signed.

=head1 SERVER OBJECT

Authen::Ticket::Server provides an object encapsulating most of the information
required to authenticate a user and generate tickets.  The following
values are contained in the object:

    $server = new Authen::Ticket::Server;
    $$server{_r}     -> Apache request object iff running under mod_perl
    $$server{stdout} -> object to print to for HTML pages
    $$server{query}  -> CGI-like object for generating HTML and accessing
                        form data
    $$server{request_uri}

    $$server{TicketDomain}  -> domain for which ticket is valid
    $$server{TicketExpires} -> default ticket lifetime

The class constructor will work with sub-classes without modification.
Sub-class initialization should be placed in the B<initialize> subroutine.

=head1 SUB-CLASSING

A sub-class is required to override any of the methods mentioned in this
documentation (e.g., authentication method, HTML forms).  Two variables
are required in the sub-class package.

=item @ISA

This array determines the classes the sub-class will inherit from.  For
a fully functioning server, this must include Authen::Ticket::Server.  If
the tickets are to be signed, Authen::Ticket::Signature is recommended.

=item %DEFAULTS

This hash contains the default values (or undef) for the configuration
options required by the sub-class.  These are set in the httpd configuration
with the PerlSetVar directive.  These are available in the $self
hash reference.

=item Example

  package My::Ticket::Server;

  @ISA = (qw/Authen::Ticket::Server Authen::Ticket::Signature/);

  %DEFAULTS = (
    TicketUserDatabase => 'mysql:users',
    TicketDatabaseUser => undef,
    TicketDatabasePassword => undef,
    TicketUserFields   => 'table:userfield:passwordfield',
  );

=head1 GENERAL METHODS

The following methods need not be redefined in any sub-classes.

=over 4

=item $server = new Authen::Ticket::Server([$r], [%options])

This will return an initialized server object.  If $r is a
reference and the code is running under mod_perl, then 
$$server{_r} will be set to $r.  Otherwise, all the arguments are
taken to belong to a hash defining the default configuration.

This method is used in Authen::Ticket->handler and is useful
in CGI scripts implementing a ticket server.  However, the preferred
use of the Authen::Ticket modules is in a mod_perl environment.

=head1 SUB-CLASS FUNCTIONS

The following conventions are used in these sections:

  $server -> server object
  $u      -> hashref of user authentication information
  $t      -> hashref of ticket information
  $s      -> additional information for inclusion in a message

=head1 SUB-CLASS REQUIRED FUNCTIONS

Any sub-class of Authen::Ticket::Server must define the following subroutines:

=item $t = $server->authenticate($u)

This subroutine returns a hashref of information to be placed in the
ticket if the user is authenticated.  If the person is not authenticated,
it should return B<undef>.

The following values are added to $t by $server->handler
after authenticated returns
successfully:

  fields -> comma separated list of fields in %$t
  uid    -> $u->{user}
  ip     -> browser IP information depending on $u->{security}
  expiry -> expiration time of the ticket

The default implementation will place a warning in the log file (if
running under mod_perl) and
refuse authentication.

=head1 SUB-CLASS RECOMMENDED FUNCTIONS

Any sub-class of Authen::Ticket::Server should define the following subroutines:

=item $q = $server->get_query_object

This subroutine returns an object used to retrieve form values and format
HTML.  This must be CGI or another class that implements the CGI interface
(e.g., a sub-class of CGI).  

The default implementation will return a
valid CGI object of type $CGI::DefaultClass.

This routine is used in the object constructor to initialize part of the
object.

=item $o = $server->get_stdout_object

This subroutine returns an object to be used as STDOUT.  This must support
the $o->print() syntax.  

The default implementation will return the
object to which STDOUT is tied (usually Apache->request object).

This routine is used in the object constructor to initialize part of the
object.

=item $u = $server->get_userinfo

This subroutine returns a hash reference to the information on the
authenticating person.  Some massaging of the data may take place.
This routine transfers data from the input form to an internal
representation for further processing.

The following fields are expected for correct authentication:

  user     -> username
  password -> password
  duration -> lifetime of the ticket
  security -> {weak,medium,strong} extent to which the browser IP is used

The default implementation will pull the above values from the query
object.

=item $c = $server->construct_cookie(%$t)

This subroutine returns an intermediate value for the ticket.  
This routine may combine
the values in %$t in any manner deemed necessary as long
as the client website can deconstruct them.

=item $c = $server->encode_cookie($c)

This subroutine encodes the cookie.  This may involve encryption or
other transforms.  However, Authen::Ticket::Signature provides the
code for signing tickets.

The default implementation base_64 encodes the cookie.

=head1 SUB-CLASS MISCELLANEOUS FUNCTIONS

Any sub-class of Authen::Ticket::Server may define the following subroutines:

=item $server->no_cookie_error_message($s)

This subroutine returns an HTML page to be sent to the browser when
the ticket server has detected a lack of support for cookies.

=item $server->no_user_password_error_message($s)

This subroutine returns an HTML page to be sent to the browser when
the server needs the authentication information from the user.  The
optional $s parameter will contain any error messages from the previous
authentication attempt if there was one.  $uri is the URI of the page
the server will return to when the user has successfully authenticated.

=item $server->go_to_uri_message

This subroutine returns an HTML page to be sent to the browser when the
user has successfully authenticated.  This page does not need to redirect
the browser to $uri.  $uri is provided to help those browsers that cannot
redirect themselves automatically.

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

perl(1), Authen::Ticket(3), Authen::Ticket::Client(3).

=cut

