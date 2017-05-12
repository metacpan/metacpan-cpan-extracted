package Apache2::AuthAny::RequestConfig;

use strict;
use Apache2::Module ();
use Apache2::Access ();
use Apache2::Request ();
use URI::Escape;
use Digest::MD5 qw(md5_hex);
use MIME::Base64;

use Apache2::Const -compile => qw(OK DECLINED REDIRECT HTTP_UNAUTHORIZED);
use Data::Dumper("Dumper");
use CGI;
use CGI::Cookie;
use Apache2::AuthAny::Cookie ();
use Apache2::AuthAny::DB ();
use Apache2::AuthAny::AuthUtil ();
our $aaDB;
our $VERSION = '0.201';

my @system_skip_auth = qw(/Shibboleth);

sub handler {
    my $r = shift;

    my $cf = Apache2::Module::get_config('Apache2::AuthAny',
                                         $r->server,
                                         $r->per_dir_config) || {};

    my $uri = $r->uri;
    my $user_gate = $cf->{AuthAnyGateURL} || '';
    my $gate_dir = $user_gate;
    $gate_dir =~ s{/[^/]*$}{};

    if ($uri eq $user_gate || ($gate_dir && $uri =~ m{^$gate_dir}) ) {
        # Prevent any authentication attempt on the gate page.
        $r->log->info("RequestConfig: On gate page, '$uri'");
        $r->set_handlers(PerlAuthenHandler => "sub {Apache2::Const::OK}");
        $r->set_handlers(PerlAuthzHandler  => "sub {Apache2::Const::OK}");
    } elsif ($uri =~ m{/aa_auth/(.*?)/}) {
        my $provider_string = $1;
        my ($auth_provider, $logout_key) = split("_aa-key_", $provider_string);
        $r->log->info("Apache2::AuthAny::RequestConfig: Authenticating with '$auth_provider'");

        if  (lc($r->auth_type) eq 'auth-any') {
            # This auth provider does not use the Authen/Authz phases. To prevent
            # errors from DocumentRoot level Require directives, disable the
            # Authen/Authz phases
            $r->set_handlers(PerlAuthenHandler => "sub {Apache2::Const::OK}");
            $r->set_handlers(PerlAuthzHandler  => "sub {Apache2::Const::OK}");
        }

        my $pid = Apache2::AuthAny::Cookie::pid($r);
        $r->pnotes(pid => $pid);

        if ($auth_provider ne 'google') { # Google auth using PHP
            $r->handler('perl-script');
            $r->set_handlers(PerlResponseHandler => 'Apache2::AuthAny::Cookie::post_login');
        }

        if (lc($r->auth_type) eq 'basic') {
            # The AuthName randomizer is needed for IE to keep it
            # from skipping the challenge when a known AuthName is sent.
            my $auth_name = $r->auth_name() || 'Private';
            my $rand_int = int(100000 * (1 + rand(4)));
            $r->auth_name($auth_name . $rand_int);

            # Make sure the auth request is going to the current directory
            if ($logout_key ne $pid->{logoutKey}) {
                Apache2::AuthAny::AuthUtil::goToGATE($r, 'tech', {msg => "mismatching logout keys."})
            }

            # After successful authentication, set a new logoutKey
            $r->set_handlers(PerlFixupHandler => 'Apache2::AuthAny::FixupHandler::update_logout_key');

            # Go to meta redirect to GATE instead of showing ugly browser message
            # if user chooses "Cancel" on challenge popup.
            my $req = Apache2::Request->new($r);
            my $request = $req->param('req');
            my $custom_response = <<"RESPONSE";
<html>
<head>
<meta http-equiv="refresh" content="0;url=$request">
</head>
<body>
<!-- Click <a href="$request">here</a> to continue -->
</body>
</html>
RESPONSE
            $r->custom_response(Apache2::Const::HTTP_UNAUTHORIZED, $custom_response);
            $r->log->info("Apache2::AuthAny::RequestConfig: Basic custom_response set");
        }

    } elsif (lc($r->auth_type) eq 'auth-any') {
        $aaDB = Apache2::AuthAny::DB->new() unless $aaDB;

        my $pid;
        my $scripted_pid = get_scripted_pid($r, $cf);

        # First, check for scripted access by looking in "Authorization" header
        if ($scripted_pid) {
            $pid = $scripted_pid;
        } else {
            $pid = Apache2::AuthAny::Cookie::pid($r);
        }
        $r->pnotes(pid => $pid);

        my $req = Apache2::Request->new($r);
        if (defined $req->param('aalogout') ) {
            return Apache2::AuthAny::AuthUtil::logout($r, $pid);
        }

        if (defined $req->param('aalogin') ) {
            return Apache2::AuthAny::AuthUtil::goToGATE($r, 'first_access');
        }

        my $skip_patterns = $cf->{AuthAnySkipAuthentication} || [];
        push @$skip_patterns, @system_skip_auth;
        my @matching_patterns = grep {$r->uri =~ m!$_!} @$skip_patterns;
        if (@matching_patterns) {
            $r->set_handlers(PerlAuthenHandler => "sub {Apache2::Const::OK}");
            $r->set_handlers(PerlAuthzHandler => "sub {Apache2::Const::OK}");
        } else {
            $r->set_handlers(PerlAuthenHandler => 'Apache2::AuthAny::AuthenHandler');
            $r->set_handlers(PerlAuthzHandler => 'Apache2::AuthAny::AuthzHandler');
        }
        # If we make it through authen and authz, update the last access
        $r->set_handlers(PerlFixupHandler => 'Apache2::AuthAny::FixupHandler');
        set_env($r, $pid, $cf);
    }
    return Apache2::Const::DECLINED;
}

sub set_env {
    my ($r, $pid, $cf) = @_;

    my ($authId, $authProvider);
    unless ($pid->{state} eq 'logged_out') {
        ($authId, $authProvider) = ($pid->{authId}, $pid->{authProvider});
    }

    if ($pid->{scripted}) {
        $r->subprocess_env('AA_SCRIPTED' => 1);
    }

    if ($authId && $pid->{SID}) {
        # login occurred in this browser session
        $r->subprocess_env('AA_SESSION' => 1);
    }

    # resolve identity if possible
    my $identifiedUser = $aaDB->getUserByAuthIdAndProvider($authId, $authProvider) || {};
    my $user;
    if ($identifiedUser->{username}) {
        $user = $identifiedUser->{username};

        my $roles = $aaDB->getUserRoles($identifiedUser->{UID});
        $r->subprocess_env(AA_ROLES => join(",", @$roles));

        # role choices are never used in Require directives
        my %user_role_choice;
        my $role_choices = $aaDB->getUserRoleChoices($identifiedUser->{UID});
        foreach my $role (@$role_choices) {
            $user_role_choice{$role} = 1;
        }
        my @roles_active = grep { $user_role_choice{$_} } @$roles;
        $r->subprocess_env(AA_ROLES_ACTIVE => join(",", @roles_active));

        my $identities = $aaDB->getUserIdentities($identifiedUser->{UID});
        my @idents = map {"$_->{authId}|$_->{authProvider}"} @$identities;
        $r->subprocess_env(AA_IDENTITIES => join(",", @idents));

        foreach my $field (keys %$identifiedUser) {
            $r->subprocess_env("AA_IDENT_$field" => $identifiedUser->{$field});
        }
    } elsif ($authId && $authProvider) {
        $user = "$authId|$authProvider";
    }

    $r->user($user) if $user;
    $r->subprocess_env(REMOTE_USER => $user);

    $r->subprocess_env(AA_USER => $authId);
    $r->subprocess_env(AA_PROVIDER => $authProvider);

    # Timeout
    my $timeout = 155520000; # defaults to 5 years
    if (defined $identifiedUser->{timeout}) {
        $timeout = $identifiedUser->{timeout};
    } elsif (defined $cf->{AuthAnyTimeout}) {
        $timeout = $cf->{AuthAnyTimeout};
    }

    if ($pid->{state} eq 'authenticated' && time() - $pid->{last} < $timeout) {
        $r->subprocess_env(AA_TIMEOUT => $timeout);
    } elsif ($authId ) {
        $aaDB->statePCookie($pid, 'recognized');
    } else {
        $aaDB->statePCookie($pid, 'logged_out');
    }

    $r->subprocess_env(AA_STATE => $pid->{state});
    # Passing gate for logout convienience
    $r->subprocess_env();
}

sub get_scripted_pid {
    my $r = shift;
    my $cf = shift;
    if ($cf->{AuthAnyBasicAuthUserFile}) {
        unless (open(HTPASSWD, $cf->{AuthAnyBasicAuthUserFile})) {
            my $msg = "Cannot read  '$cf->{AuthAnyBasicAuthUserFile}' $!";
            die $msg;
        }

        my ($http_user, $http_password) = get_user_and_password($r);
        if ($http_user && $http_password) {

            my $stored_passwd;
            while (<HTPASSWD>) {
                chomp;
                my ($username, $crypt_passwd) = split(":", $_, 2);
                if ($username eq $http_user) {
                    if (crypt($http_password, $crypt_passwd) eq $crypt_passwd) {
                        $r->log->info("RequestConfig: From HTTP header: $username");
                        return {PID => 'unused',
                                SID => 'unused',
                                logoutKey => 'unused',
                                state => 'authenticated',
                                scripted => 1,
                                authId => $username,
                                authProvider => 'basic',
                                last => 2298416724, # time in the future
                               };
                    } else {
                        my $msg = "RequestConfig: Basic user found in " .
                          "$cf->{AuthAnyBasicAuthUserFile}, however password is incorrect";
                        $r->log->warn($msg);
                        last;
                    }
                }
            }
        }
    }
}

sub get_user_and_password {
    my $r = shift;
    my $Authorization = $r->headers_in->{Authorization};
    if ($Authorization) {
        my ($type, $hash) = split " ", $Authorization;
        my $u_and_p = decode_base64($hash);
        if ($u_and_p) {
            my ($user, $password) = split(/:/, $u_and_p, 2);
            return ($user, $password);
        }
    }
    return undef;
}

1;
