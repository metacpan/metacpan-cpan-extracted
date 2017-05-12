
use strict;
package TestApp;
use base 'CGI::Application::Framework';

sub stash {
    my $self = shift;

    $self->{'__x_STASH'} = $_[0] if ref $_[0] eq 'HASH';
    $self->{'__x_STASH'} ||= {};
    return $self->{'__x_STASH'};
}

sub setup {
    my $self = shift;
    $self->header_type('none');

    my $stash = $self->stash;
    $stash->{'Final_Run_Mode'}  = undef;
    $stash->{'Seen_Run_Mode'}   = undef;
    $stash->{'User_OK'}         = undef;
    $stash->{'Password_OK'}     = undef;
    $stash->{'Suppress_Output'} = $self->param('suppress_output') || undef;
}
sub header_props {
    my $self = shift;
    my %args = @_;
    my $stash = $self->stash;

    $stash->{'Cookie'} = $args{'-cookie'};
}

sub _login_tmpl_params {
    ();
}

sub config_file {
    't/conf/testapp.conf';
}
sub db_config_file {
    't/conf/testapp.conf';
}
sub find_log_config_file {
    't/conf/testlog4perl.conf';
}
sub _login_profile {
    return {
        required => [ qw ( username password ) ],
        msgs     => {
            any_errors => 'some_errors', # just want to set a true value here
            prefix     => 'err_',
        },
    };
}
sub _login_authenticate {
    my $self     = shift;
    my $user     = undef;
    my $username = $self->query->param('username');
    my $stash = $self->stash;

    ($user) = TestCDBI::Users->search(
        username => $username
    ) if length($username);

    if ($user) {
        $stash->{'User_OK'} = 1;
    }
    ($stash->{'Password_OK'}, $user) = $self->_password_authenticate_user($user);
    return ($stash->{'Password_OK'}, $user);
}
sub _password_authenticate_user {

    my $self = shift;
    my $user = shift;

    if ( $user ) {
        if ( $self->query->param('password') eq $user->password() ) {
            return (1, $user); # password check good
        } else {
            return (0, $user); # password check failed
        }
    }
    else {
        return (0, undef);
    }
}
sub _login_failed_errors {
    my $self = shift;

    my $is_login_authenticated = shift;
    my $user = shift;
    my $errs = undef;

    if ( $user && (!$is_login_authenticated) ) {
        $errs->{'err_password'} = 'Incorrect password for this user';
    }
    elsif ( ! $user ) {
        $errs->{'err_username'} = 'Unknown user';
    }
    else {
        die "Can't happen! ";
    }
    $errs->{some_errors} = '1';

    return $errs;
}
sub _initialize_session {

    my $self = shift;
    my $user = shift;

    $self->session->{uid}      = $user->uid;
    $self->session->{user_id}  = $user->uid;
    $self->session->{username} = $user->username;
    $self->session->{fullname} = $user->fullname;
    $self->session->{wubba}    = 'yes';

    return 1;
}

sub login {
    my $self = shift;

    my $stash = $self->stash;
    $stash->{'Seen_Run_Mode'}{'login'} = 1;
    $stash->{'Final_Run_Mode'} = 'login';

    # When login is run via ValidateRM, we have to return text to
    # indicate to the Framework that we actually ran the login page

    # When login is run directly, we can't return text or we'll screw
    # up the tests

    return $stash->{'Suppress_Output'} ? '' : 'login page yada yada yada';
}

sub _echo_page {
    my $self = shift;
    my $stash = $self->stash;

    $stash->{'Seen_Run_Mode'}{'_echo_page'} = 1;
    $stash->{'Final_Run_Mode'}              = '_echo_page';
    '';
}

sub main_display {
    my $self    = shift;
    my $stash = $self->stash;

    $stash->{'Seen_Run_Mode'}{'main_display'} = 1;
    $stash->{'Final_Run_Mode'}                = 'main_display';
    '';
}


1;

