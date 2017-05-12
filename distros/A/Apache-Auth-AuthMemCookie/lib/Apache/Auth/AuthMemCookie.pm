package Apache::Auth::AuthMemCookie;

use strict;
use CGI::Cookie ();
use Apache2::RequestUtil;
use Apache2::RequestIO;
use APR::Table;
use Apache2::RequestRec;
use Apache2::Const -compile => qw(OK REDIRECT FORBIDDEN AUTH_REQUIRED);
use Apache2::Log;
use Cache::Memcached;
use vars qw($VERSION);
$VERSION = '0.04';

use Data::Dumper;

=pod

=head1 B<Apache::Auth::AuthMemCookie - Authenticate using a memcache stored session>

=head2 B<Module Usage>

=over

  This module is used to take the place of Apache2 authmemcookie primarily for the use
  of integration with simpleSAMLphp L<http://rnd.feide.no/simplesamlphp> .

    Alias /simplesaml /home/piers/git/public/simplesamlphp/www
    perlModule Apache::Auth::AuthMemCookie
    ErrorDocument 401 "/simplesaml/authmemcookie.php"
    PerlRequire /path/to/authmemcookie/tools/startup.pl
    perlModule Apache::Auth::AuthMemCookie

    # Prompt for authentication:
    <Location /location_to_protect>
        AuthType Cookie
        AuthName "My Service"
        Require valid-user
        PerlAuthenHandler Apache::Auth::AuthMemCookie::authen_handler
        PerlSetVar AuthMemCookie "AuthMemCookie"
        PerlSetVar AuthMemServers "127.0.0.1:11211, /var/sock/memcached"
        PerlSetVar AuthMemAttrsInHeaders 1 # if you want to set headers instead of ENV vars
        PerlSetVar AuthMemDebug 1 # if you want to debug
    </Location>

=back

=cut

our $memd = undef;
our $DEBUG = 0;

     
sub authen_handler {
  
    my $r = shift;
    $DEBUG = $r->dir_config("AuthMemDebug") || 0;

    # first, remove all headers and env vars that might have been injected
    foreach my $k (keys %ENV) {
        delete $ENV{$k} if $k =~ /^(ATTR_|UserName)/;
    }
    foreach my $h (keys %{$r->headers_in}) {
        $r->headers_in->unset($h) if $h =~ /^(ATTR_|UserName|X_REMOTE_USER|HTTP_X_REMOTE_USER)/;
    }
    $r->headers_in->unset('UserName');
    $r->headers_in->unset('X_REMOTE_USER');
    $r->headers_in->unset('X-Remote-User');

    # what is our cookie called
    my $cookie_name = $r->dir_config("AuthMemCookie") ? $r->dir_config("AuthMemCookie") : 'AuthMemCookie';
    mydebug("Headers in: ".Dumper($r->headers_in));

    # sort out our memcached connection
    unless ($memd) {
        my @memd_servers = split /\s*(?:,)\s*/, ($r->dir_config("AuthMemServers") ? $r->dir_config("AuthMemServers") : '127.0.0.1:11211, /var/sock/memcached');
        $memd = new Cache::Memcached {
            'servers' => [ @memd_servers ],
            'debug' => 0,
            'compress_threshold' => 10_000,
           };
        mydebug("memcache servers: ".Dumper(\@memd_servers));
    }

    # get and process the cookies 
    my $cookies = $r->headers_in->get('Cookie');
    $cookies = parse CGI::Cookie($cookies);
    my $auth_cookie = exists $cookies->{$cookie_name} ? $cookies->{$cookie_name}->value() : "";

    # do we have the AuthMemCookie?
    unless ($auth_cookie) {
        mydebug("AuthMemCookie does not exist ($cookie_name) -> forcing login");
        return Apache2::Const::AUTH_REQUIRED;
    }
    my $val = $memd->get($auth_cookie);

    # Do we have a valid Memcached session?
    unless ($val) {
        mydebug("Memcached session not found for AuthMemCookie ($cookie_name): $auth_cookie");
        return Apache2::Const::AUTH_REQUIRED;
    }

    mydebug("AuthMemCookie value: $val");

    # we found a valid MemCache session so push it into the environment and let them go
    my %vars = map { my ($k, $v) = split(/=/, $_, 2); $k => $v } (split(/\r\n/, $val));

    # should the values be set in the headers
    my $header_switch = $r->dir_config("AuthMemAttrsInHeaders") ? $r->dir_config("AuthMemAttrsInHeaders") : 0;
    my $user = "";
    foreach my $k (keys %vars) {
      if ($k eq "UserName") {
          $user = $vars{$k};
      }
      if ($header_switch) {
          mydebug("setting Header $k => $vars{$k}");
          if ($k eq "UserName") {
            $r->headers_in->add('X-Remote-User' => $vars{$k});
          }
          else {
            $r->headers_in->add($k => $vars{$k});
          }
      }
      else {
          mydebug("setting ENV $k => $vars{$k}");
          $ENV{$k} = $vars{$k};
      }
    }
      mydebug("The user name is: $user");
    $r->user($user);
    return Apache2::Const::OK;
}

sub mydebug {
  if ($DEBUG) {
      warn @_;
  }
}
     
1;
