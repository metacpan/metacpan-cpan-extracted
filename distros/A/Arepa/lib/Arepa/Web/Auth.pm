package Arepa::Web::Auth;

use strict;
use warnings;

use English qw(-no_match_vars);
use base 'Arepa::Web::Base';
use DBI;
use Digest::MD5;
use YAML;
use MojoX::Session;

# Let session cookies live one week
use constant TTL_SESSION_COOKIE => 60 * 60 * 24 * 7;

sub _check_credentials {
    my ($self, $username, $password, $auth_type) = @_;

    if (defined $auth_type && $auth_type eq 'file_md5') {
        my $user_file_path =
          $self->config->get_key('web_ui:authentication:user_file');
        my %users = %{YAML::LoadFile($user_file_path)};
        return ($users{users}->{$username} eq Digest::MD5::md5_hex($password));
    }
    elsif (!defined $auth_type) {
        my %users = %{YAML::LoadFile($self->config->
                                            get_key('web_ui:user_file'))};
        return ($users{$username} eq Digest::MD5::md5_hex($password));
    }
    else {
        die "Broken configuration: unknown auth type '$auth_type'\n";
    }
}

sub _get_session {
    my ($self) = @_;

    my $session_db = $self->config->get_key('web_ui:session_db');
    my $dbh = DBI->connect("dbi:SQLite:dbname=$session_db");
    my $session = MojoX::Session->new(tx            => $self->tx,
                                      store         => [dbi => {dbh => $dbh}],
                                      expires_delta => TTL_SESSION_COOKIE);


    # External authentication
    my $auth_type_key = 'web_ui:authentication:type';
    my $auth_type;
    if ($self->config->key_exists($auth_type_key)) {
        $auth_type = $self->config->get_key($auth_type_key);
    }

    if (defined $auth_type && $auth_type eq 'external') {
        if ($ENV{REMOTE_USER}) {
            $session->load;
            if (! $session->sid || $session->is_expired) {
                $session->create;
                $session->data(username => $ENV{REMOTE_USER});
                $session->flush;
            }
        }
        else {
            $self->vars("error" => "Authentication error: your webserver is " .
                                       "not passing the REMOTE_USER " .
                                       "environment variable to the " .
                                       "application");
        }
    }
    else {
        if (defined $self->param('username') &&
                defined $self->param('password')) {
            my $valid_creds;
            eval {
                $valid_creds =
                  $self->_check_credentials($self->param('username'),
                                            $self->param('password'),
                                            $auth_type);
            };
            if ($EVAL_ERROR) {
                $self->vars("error" => $EVAL_ERROR);
            }
            else {
                if ($valid_creds) {
                    $session->create;
                    $session->data(username => $self->param('username'));
                    $session->flush;
                }
                else {
                    $self->vars("error" => "Invalid username or password");
                }
            }
        } else {
            $session->load;
        }
    }

    # Figure out if the logged in user is an admin
    if (defined $auth_type) {
        my $user_file_path =
          $self->config->get_key('web_ui:authentication:user_file');
        my %users = %{YAML::LoadFile($user_file_path)};
        my $is_admin = scalar(grep { $_ eq $session->data('username'); }
                              @{$users{admins}});
        $session->data(is_user_admin => $is_admin);
    }
    else {
        $session->data(is_user_admin => 1);
    }

    $self->stash(username      => $session->data('username'),
                 is_user_admin => $session->data('is_user_admin'));
    return $session;
}

sub login {
    my $self = shift;

    my $session = $self->_get_session;

    if ($session->sid && ! $session->is_expired) {
        return 1;
    }
    else {
        # Don't check anything for public URLs
        my $url_parts = $self->tx->req->url->path->parts;
        if (scalar @$url_parts && $url_parts->[0] eq 'public') {
            return 1;
        }
    }

    $self->vars();
    $self->render('auth/login', layout => 'default');
    return 0;
}

sub logout {
    my $self = shift;

    my $session_db = $self->config->get_key('web_ui:session_db');
    my $dbh = DBI->connect("dbi:SQLite:dbname=$session_db");
    my $session = MojoX::Session->new(tx    => $self->tx,
                                      store => [dbi => {dbh => $dbh}]);
    $session->expire;
    $session->flush;

    $self->redirect_to('home');
}

1;
