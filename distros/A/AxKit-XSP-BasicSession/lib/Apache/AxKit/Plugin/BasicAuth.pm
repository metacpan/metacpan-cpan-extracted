package Apache::AxKit::Plugin::BasicAuth;
# $Id: BasicAuth.pm,v 1.3 2004/08/19 22:31:21 nachbaur Exp $

use strict;
use Apache;
use Apache::Constants qw(:common M_GET);
use Apache::AuthCookie;
use Apache::Session::Flex;
use Apache::Util qw(escape_uri);
use Digest::MD5 qw(md5_hex);
use vars qw($VERSION);
use base qw(Apache::AuthCookie);

use constant IN_PROGRESS => 1;

$VERSION = 0.19;

sub authen_cred {
    my $self = shift;
    my $r = shift;
    my @creds = @_;

    # Don't call this unless you've authenticated the user.
    return $Apache::AxKit::Plugin::BasicSession::session{"_session_id"}
        if (defined $Apache::AxKit::Plugin::BasicSession::session{"credential_0"});
}

sub authen_ses_key ($$$) {
    my $self = shift;
    my $r = shift;
    my $sess_id = shift;

    # Session handling code
    return $Apache::AxKit::Plugin::BasicSession::session{credential_0}
        if ($Apache::AxKit::Plugin::BasicSession::session{_session_id} eq $sess_id);

#    untie %Apache::AxKit::Plugin::BasicSession::session
#      if (ref tied %Apache::AxKit::Plugin::BasicSession::session);

    my $prefix = $r->auth_name;

    my %flex_options = (
        Store     => $r->dir_config( $prefix . 'DataStore' ) || 'DB_File',
        Lock      => $r->dir_config( $prefix . 'Lock' ) || 'Null',
        Generate  => $r->dir_config( $prefix . 'Generate' ) || 'MD5',
        Serialize => $r->dir_config( $prefix . 'Serialize' ) || 'Storable'
    );

    # Load session-type specific parameters
    foreach my $arg ( split( /\s*,\s*/, 
			     $r->dir_config( $prefix . 'Args' ) ) ) {
        my ($key, $value) = split( /\s*=>\s*/, $arg );
        $flex_options{$key} = $value;
    }

    eval { tie %Apache::AxKit::Plugin::BasicSession::session,
	     'Apache::Session::Flex',
	     $sess_id, \%flex_options; };

    # invoke the custom_errors handler so we don't get fried...
    return (0, 0)
      unless defined
	$Apache::AxKit::Plugin::BasicSession::session{"credential_0"};

    return $Apache::AxKit::Plugin::BasicSession::session{"credential_0"};
}

sub login_form {
    my $self = shift;
    my $r = Apache->request or die "no request";
    my $auth_name = $r->auth_name || 'BasicSession';
    my $cgi = Apache::Request->instance($r);

    # There should be a PerlSetVar directive that gives us the URI of
    # the script to execute for the login form.

    my $authen_script;
    unless ($authen_script = $r->dir_config($auth_name . "LoginScript")) {
        $r->log_reason("PerlSetVar '${auth_name}LoginScript' not set", $r->uri);
        return SERVER_ERROR;
    }

    $r->internal_redirect($authen_script);
}

sub logout {
    my $self = shift;
    my $r    = shift;
    my $session = shift;

    foreach(keys %{$session}) {
        delete $session->{$_} if(/^credential_\d+/);
    }
}

sub custom_errors {
    my ($auth_type, $r, $auth_user, @args) = @_;

    $r->subprocess_env('AuthCookieReason', 'bad_cookie');

    # They aren't authenticated, and they tried to get a protected
    # document.  Send them the authen form.
    return $auth_type->login_form;
}

# This function disabled since we rely on session management for cookie setting.
sub send_cookie { }

1;
