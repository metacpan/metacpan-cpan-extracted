use warnings;
use strict;

=head1 NAME

CommitBit::Action::Login

=cut

package CommitBit::Action::Login;
use base qw/CommitBit::Action/;

__PACKAGE__->mk_accessors(qw/user/);

=head2 arguments

Return the email and password form fields

=cut

use Jifty::Param::Schema;
use Jifty::Action schema {
    param
        email => label is 'Email address',
        is mandatory, ajax validates;
    param
        password => type is 'password',
        label is 'Password', is mandatory;

    param
        remember => type is 'checkbox',
        label is 'Remember me?',
        hints is 'If you want, your browser can remember your login for you',
        default is 0;

};

=head2 take_action

Actually check the user's password. If it's right, log them in.
Otherwise, throw an error.


=cut

sub take_action {
    my $self = shift;

    if ( $self->validate_login ) {
        $self->login_as_user( $self->user );
        $self->success_message;
        return 1;
    }

    $self->error_message();

    return 0;
}

sub validate_login {
    my $self = shift;

    $self->user( $self->new_currentuser( email => $self->argument_value('email') ) );
    if ( !$self->user->id ) {
        $self->log->debug('No record found in db');
        return 0;
    }
    if ( !$self->user->password_is( $self->argument_value('password') ) ) {
        $self->log->debug('Invalid password');
        return 0;
    };


    unless (  $self->user->user_object->email_confirmed ) {
     warn "". defined $self->user->user_object->email_confirmed?1:0 ."";
        $self->log->debug('Unconfirmed' . 
      Jifty::YAML::Dump($self->user->user_object->{'values'}));
        $self->result->error(q{You haven't confirmed your account yet.});
        return 0;
    }

    return 1;
}

sub login_as_user {
    my $self = shift;
    my $user = shift;

    # Actually do the signin thing.
    Jifty->web->current_user($user);
    Jifty->web->session->expires(
        $self->argument_value('remember') ? '+1y' : undef );
    Jifty->web->session->set_cookie;

}

sub success_message {
    my $self = shift;

    # Set up our login message
    $self->result->message("Welcome back!");

}

sub error_message {
    my $self = shift;
    unless ( $self->result->error ) {
        $self->result->error(
            q{You may have mistyped something. Give it another shot?});
    }

}

sub new_currentuser {
    my $self = shift;
    my $user = CommitBit::CurrentUser->new(@_);
    return $user;

}
1;
