package Apache::AuthCASSimple;

use strict;
use warnings;

use Apache::Constants qw(:common :response M_GET);
use Apache::ModuleConfig;
use Apache::Log;
use Apache::Session::Wrapper;
use DynaLoader ();
use Authen::CAS::Client;
use vars qw($VERSION);

$VERSION = '0.0.4';

if($ENV{MOD_PERL}) {
  no strict;
  @ISA = qw(DynaLoader);
  __PACKAGE__->bootstrap($VERSION);
}

#
# handler()
#
# Called by apache/mod_perl
#
sub handler ($) {
  my $r = shift;
  my $log = $r->log();


  # does it need to do something ?
  return DECLINED unless($r->auth_type() eq __PACKAGE__);

  $log->info(__PACKAGE__.": Entering into authentification process.:".$r->uri() ."--".$r->args());

  # Get module config (Apache directive values)
  my $cfg = Apache::ModuleConfig->get($r, __PACKAGE__);


  # Check for internal session
  my $user;
  if($cfg->{_cas_session_timeout} >= 0 && ($user = _get_user_from_session($r))) {
    $log->info(__PACKAGE__.": Session found for user $user.");
    $r->connection->user($user);
    return OK;
  }
  elsif($cfg->{_cas_session_timeout} >= 0) {
    $log->info(__PACKAGE__.": No session found.");
  }
  else {
    $log->info(__PACKAGE__.": Session disabled.");
  }

  # instance CAS object
  my ($cas, %options);
  $options{casUrl} = ($cfg->{_cas_ssl} ? 'https://' : 'http://').$cfg->{_cas_name}.':'.$cfg->{_cas_port}.$cfg->{_cas_path};
 # $options{CAFile} = $cfg->{_ca_file} if ($cfg->{_cas_ssl});

  unless($cas = Authen::CAS::Client->new($options{casUrl}, fatal => 1)) {
    $log->error(__PACKAGE__.": Unable to create CAS instance.");
    return SERVER_ERROR;
  }

  my $requested_url = _get_requested_url($r,$cfg);
  my $login_url = $requested_url;
  # TODO better clean url
  $login_url =~ s/\?/\&/;
  $login_url = $cas->login_url().$login_url;

  # redirect to CAS server unless ticket parameter
  my %args = $r->args();
  unless ($args{ticket}) {
    $log->info(__PACKAGE__.": No ticket, client redirected to CAS server.");
    $r->err_header_out("Location" => $login_url);
    return REDIRECT;
  }


  # Validate the ticket we received
  if ($args{ticket}=~/^PT/) {
      my $r = $cas->proxy_validate( $requested_url, $args{ticket} );
        if( $r->is_success() ) {
            $user=$r->user();
            $log->warn(__PACKAGE__.": Validate PT on CAS Proxy server. ".join ",", $r->proxies());
        };
  }
  else {
      my $r = $cas->service_validate( $requested_url, $args{ticket} );
      if ( $r->is_success() ) {
        $user = $r->user();
      }
  }

  unless ($user) {
    $log->warn(__PACKAGE__.": Unable to validate ticket ".$args{ticket}." on CAS server.");
    $r->err_header_out("Location" => $login_url);
    return REDIRECT;
    #return FORBIDDEN;
  }

  $log->info(__PACKAGE__.": Ticket ".$args{ticket}." succesfully validated.");

  if ( $user ) {
   $r->connection->user($user);

   $log->info(__PACKAGE__.": New session ".$r->uri() ."--".$r->args());

   # if we are there (and timeout is set), we can create session data and cookie
   _remove_ticket($r);
   _create_user_session($r) if($cfg->{_cas_session_timeout} >= 0);
   $r->err_header_out("Location" => $r->uri . ($r->args ? '?' . $r->args : '') );
   # if session, redirect remove ticket in url
   return ($cfg->{_cas_session_timeout}  >= 0)?REDIRECT:OK;
  }

  return FORBIDDEN;

}

#
# _get_requested_url()
#
# Return the URL requested by client (with args)
#
sub _get_requested_url ($$) {
  my $r = shift;
  my $cfg = shift;

  my $port = $r->get_server_port();
  my $is_https = $r->subprocess_env('https') ? 1 : 0;

  my $url = $is_https ? 'https://' : 'http://';
  $url .= $r->hostname();
  $url .= ':'.$port if (!$cfg->{_mod_proxy} && ( ($is_https && $port != 443) || (!$is_https && $port != 80) ));
  $url .= $r->uri()._get_query_string($r);

  return $url;
}

#
# _get_query_string()
#
# Return the query string
#
sub _get_query_string ($) {
  my $r = shift;

  _post_to_get($r) if ($r->method eq 'POST');

  my %args = $r->args();
  my @qs = ();

  foreach (sort {$a cmp $b} keys(%args)) {
    next if ($_ eq 'ticket');
    push(@qs, $_."=".$args{$_});
  }

  return $#qs != -1 ? "?".join("\&", @qs) : "";
}

#
# _post_to_get()
#
# Convert POST data to GET
#
sub _post_to_get ($) {
  my $r = shift;

  my $content = $r->content;
  $r->log()->info($content);
  $r->method("GET");
  $r->method_number(M_GET);
  $r->headers_in->unset("Content-length");
  $r->args($content);
}

#
# _remove_ticket
#
# Remove ticket from query string arguments
#
sub _remove_ticket ($) {
  my $r = shift;

  my %args = $r->args();
  my @qs = ();

  foreach (sort {$a cmp $b} keys(%args)) {
    next if ($_ eq 'ticket');
    push(@qs, $_."=".$args{$_});
  }

  $r->args(join("\&", @qs));
}

#
# _get_user_from_session()
#
# Retrieve username if a session exist ans is correctly filled
#
sub _get_user_from_session ($) {
  my $r = shift;
  my $s;

  my $cfg = Apache::ModuleConfig->get($r, __PACKAGE__);

  $r->log()->info(__PACKAGE__.": Checking session.");

    eval { $s = Apache::Session::Wrapper->new(
        class  => 'File',
        directory => $cfg->{_cas_session_dir},
        lock_directory  => $cfg->{_cas_session_dir},
        use_cookie => 1,
        cookie_secure => $r->subprocess_env('https') ? 1 : 0,
        cookie_resend => 1,
        cookie_expires => 'session',
        cookie_path => $cfg->{'_cas_cookie_path'}
    ); };

    #$r->log()->info(__PACKAGE__.":IDIDIDID:".$s->{'session_id'});

    return "" unless(defined $s);


    if ($cfg->{_cas_session_timeout} && $s->session->{'time'} + $cfg->{_cas_session_timeout} < time) {
        $r->log()->warn(__PACKAGE__.": Session TimeOut !");
        $s->delete_session();
        return "";
    };

  my $ip = ($cfg->{_mod_proxy})?$r->header_in('X-Forwarded-For'):$r->connection->remote_ip();


  if($s->session->{'CASIP'} ne $ip) {
    $r->log()->warn(__PACKAGE__.": Remote IP Address changed along requests !");
    $s->delete_session();
    return "";
  }
  elsif(my $user = $s->session->{'CASUser'}) {
    return $user;
  }
  else {
    $r->log()->warn(__PACKAGE__.": Session found, but no data inside it.");
    $s->delete_session();
    return "";
  }
}

#
# _create_user_session()
#
# Create a user session and send cookie
#
sub _create_user_session ($) {
  my $r = shift;
  my $cfg = Apache::ModuleConfig->get($r, __PACKAGE__);

  $r->log()->info(__PACKAGE__.": Creating session");

  my $s = Apache::Session::Wrapper->new(
        class  => 'File',
        directory => $cfg->{_cas_session_dir},
        lock_directory  => $cfg->{_cas_session_dir},
        use_cookie => 1,
        cookie_secure => $r->subprocess_env('https') ? 1 : 0,
        cookie_resend => 1,
        cookie_expires => 'session',
        cookie_path => $cfg->{'_cas_cookie_path'}
        );

    #$r->log()->info(__PACKAGE__.":CCCCIDIDIDID:".$s->{'session_id'});
  unless ($s) {
    $r->log()->warn(__PACKAGE__.": Unable to create session for ".$r->connection->user().".");
    return;
  }

  $s->session->{'CASUser'} = $r->connection->user();
  my $ip = ($cfg->{_mod_proxy})?$r->header_in('X-Forwarded-For'):$r->connection->remote_ip();
  $s->session->{'CASIP'} = $ip;
  $s->session->{'time'} = time();

};

#
# CASServerName()
#
# Callback for CASServerName apache directive
#
sub CASServerName ($$$) {
  my ($cfg, $parms, $arg) = @_;

  die "Invalid CAS Server name $arg." unless ($arg =~ m/^(.+)$/);

  $cfg->{_cas_name} = $arg;
}

#
# CASServerPath()
#
# Callback for CASServerPath apache directive
#
sub CASServerPath ($$$) {
  my ($cfg, $parms, $arg) = @_;

  die "Invalid CAS Server path $arg." unless ($arg =~ m/^\//);

  $arg = '' if $arg eq '/';
  $cfg->{_cas_path} = $arg;

}

#
# CASServerPort()
#
# Callback for CASServerPort apache directive
#
sub CASServerPort ($$$) {
  my ($cfg, $parms, $arg) = @_;

  die "Invalid CAS Server port $arg." unless ($arg =~ m/^\d+$/);

  $cfg->{_cas_port} = $arg;
}

#
# CASServerNoSSL()
#
# Callback for CASServerNoSSL apache directive
#
sub CASServerNoSSL ($$) {
  shift->{_cas_ssl} = 0;
}


#
# CASSessionTimeout()
#
# Callback for CASSessionTimeout apache directive
#
sub CASSessionTimeout ($$$) {
  my ($cfg, $parms, $arg) = @_;

  die "Invalid CAS session timeout $arg." unless ($arg =~ m/^-?\d+$/);

  $cfg->{_cas_session_timeout} = $arg;
}

#
# CASSessionDirectory()
#
# Callback for CASSessionTimeout apache directive
#
sub CASSessionDirectory ($$$) {
  my ($cfg, $parms, $arg) = @_;

  die "Invalid CAS session directory $arg (does not exist or is not writable)." unless (-d $arg && -w $arg);

  $cfg->{_cas_session_dir} = $arg;
}

#
# CASCaFile()
#
# Callback for CASCaFile apache directive
#
sub CASCaFile ($$$) {
  my ($cfg, $parms, $arg) = @_;

  die "Invalid CA file $arg." unless (-e $arg);

  $cfg->{_ca_file} = $arg;
}
#
# CASFixDirectory()
#
# Callback for CASFixDirectory apache directive
#
sub CASFixDirectory ($$$) {
  my ($cfg, $parms, $arg) = @_;

  die "Invalid CAS fix directory directive, path must begin with '/'." unless ($arg && $arg =~ m/^\//);

  $cfg->{_cas_cookie_path} = $arg;
}
#
# NOModProxy()
#
# Callback for NOModProxy apache directive
#
sub NOModProxy ($) {
  shift->{_mod_proxy} = 0;
}
#
# DIR_CREATE
#
# create default values 
#
sub DIR_CREATE {
  my $class = shift;
  my $self = {};

  $self->{_cas_name} = "my.cas-server.net";
  $self->{_cas_path} = "/cas";
  $self->{_cas_port} = "443";
  $self->{_cas_ssl} = 1;
  $self->{_cas_cookie_path} = "/";
  $self->{_ca_file} = "";
  $self->{_cas_session_dir} = "/tmp";
  $self->{_cas_session_timeout} = -1;
  $self->{_mod_proxy} = 1;

  return bless($self, $class);
}
#
# DIR_MERGE
#
# create default values 
#
sub DIR_MERGE {
  my ($parent, $current) = @_;

  my $new = {%$parent, %$current};

  return bless($new, ref($parent));
}

1;

__END__

=head1 NAME

Apache::AuthCASSimple - Apache module to authentificate trough a CAS server

=head1 DESCRIPTION

Apache::AuthCASSimple is a module for Apache/mod_perl. It allow you to
authentificate users trough a CAS server. It means you don't need
to give login/password if you've already be authentificate by the CAS
server, only tickets are exchanged between Web client, Apache server
and CAS server. If you not're authentificate yet, you'll be redirect
on the CAS server login form.

=head1 SYNOPSIS

  <Location /protected>
    AuthType Apache::AuthCASSimple
    PerlAuthenHandler Apache::AuthCASSimple

    CASServerName my.casserver.com
    CASServerPath /
    #CASServerPort 443
    # CASServerNoSSL
    CASSessionTimeout 60
    CASSessionDirectory /tmp
    # CASFixDirectory /
    # NOModProxy

    require valid-user
  </Location>

or require user xxx yyyy

=head1 CONFIGURATION

=over 4

=item CASServerName

Name of the CAS server. It can be a numeric IP address.

=item CASServerPort
Port of the CAS server. Default is 443.

=item CASServerPath

Path (URI) of the CAS server. Default is "/cas".

=item CASServerNoSSL

Disable SSL transaction wih CAS server (HTTPS). Default is off.

=item CASCaFile

CAS server public key. This file is used to allow secure connection
between the webserver using Apache::AuthCASSimple and the CAS server.

DEPRECATED : L<Authen::CAS::Client> use L<LWP::UserAgent> to make https requests

=item CASSessionTimeout

Timeout (in second) for session create by Apache::AuthCASSimple (to avoid CAS server overloading). Default is -1.

-1 means disable.

0 mean infinite (until the user close browser).

=item CASSessionDirectory

Directory where session data are stored. Default is /tmp.

=item CASFixDirectory

Force the path of the session cookie for same policy in all subdirectories else current directory is used.

=item NOModProxy

Apache mod_perl don't be use with mod_proxy. Default is off.

=back

=head1 METHODS

=head2 handler

used by apache

=head2 DIR_CREATE

set defaults values

=head2 DIR_MERGE

access deafault values

=head1 VERSION

This documentation describes Apache::AuthCASSimple version 0.0.4

=head1 BUGS AND TROUBLESHOOTING

=over 4

=item *
Old expired sessions files must be deleted with an external provided script : C<delete_session_data.pl>

=back

Please submit any bug reports to agostini@univ-metz.fr.


=head1 NOTES

Requires C<mod_perl 1> version 1.29 or later
Requires L<Authen::CAS::Client>
Requires L<Apache::Session::Wrapper> 

=head1 AUTHORS

    Yves Agostini
    CPAN ID: YVESAGO
    Univ Metz
    agostini@univ-metz.fr
    http://www.crium.univ-metz.fr

    Anthony Hinsinger

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
