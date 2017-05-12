package Bracket::Controller::Auth;

use Moose;
BEGIN { extends 'Catalyst::Controller' }
use Time::HiRes qw/ time /;
use Bracket::Form::Register;
use Bracket::Form::Login;
use Bracket::Form::Password::Change;
use Bracket::Form::Password::ResetEmail;
use Bracket::Form::Password::Reset;

sub debug { 0 }
require Data::Dumper if debug;


=head1 Name

Bracket::Controller::Admin - Functions for admin users
  
=head1 Description

Controller with authentication related actions:

* register
* login/logout
* change/reset password

=cut

has 'register_form' => (
    isa     => 'Bracket::Form::Register',
    is      => 'rw',
    lazy    => 1,
    default => sub { Bracket::Form::Register->new },
);

has 'login_form' => (
    isa     => 'Bracket::Form::Login',
    is      => 'rw',
    lazy    => 1,
    default => sub { Bracket::Form::Login->new },
);

has 'change_password_form' => (
    isa     => 'Bracket::Form::Password::Change',
    is      => 'rw',
    lazy    => 1,
    default => sub { Bracket::Form::Password::Change->new },
);

has 'email_reset_password_link_form' => (
    isa     => 'Bracket::Form::Password::ResetEmail',
    is      => 'rw',
    lazy    => 1,
    default => sub { Bracket::Form::Password::ResetEmail->new },
);

has 'reset_password_form' => (
    isa     => 'Bracket::Form::Password::Reset',
    is      => 'rw',
    lazy    => 1,
    default => sub { Bracket::Form::Password::Reset->new },
);

sub register : Global {
    my ($self, $c) = @_;

    $c->stash(
        template => 'form/auth/register.tt',
        form     => $self->register_form,
    );

    my $new_player = $c->model('DBIC::Player')->new_result({});
    $self->register_form->process(
        item   => $new_player,
        params => $c->request->parameters,
    );

    # This return on GET (new form) and a POSTed form that's invalid.
    return if !$self->register_form->is_valid;

    # At this stage the form has validated
    $c->flash->{status_msg} = 'Registration succeeded';
    $c->response->redirect($c->uri_for('/login'));
}

=head2 login 

Log in through the authentication system.

=cut

sub login : Global {
    my ($self, $c) = @_;

    $c->stash(
        template => 'form/auth/login.tt',
        form     => $self->login_form,
    );

    $self->login_form->process(params => $c->request->parameters,);

    # This return on GET (new form) and a POSTed form that's invalid.
    return if !$self->login_form->is_valid;

    my $is_authenticated = $c->authenticate(
        {
            email    => $self->login_form->field('email')->value,
            password => $self->login_form->field('password')->value,
        }
    );
    if (!$is_authenticated) {
        my $login_URI = $c->uri_for('/login');
        $c->response->body("Could not <big><a href='$login_URI'>login</a></big>");
        $c->detach();
    }

    my $user_id = $c->user->id;
    warn "USER ID: $user_id" if debug;

    # At this stage the form has validated
    $c->response->redirect(
        $c->uri_for($c->controller('Player')->action_for('home')) . "/${user_id}",
    );

}

=head2 logout
 
Log in through the authentication system.

=cut

sub logout : Global {
    my ($self, $c) = @_;

    $c->logout;
    $c->response->redirect($c->uri_for('/login'));

    return;
}

=head2 change_password

Change player password

=cut

sub change_password : Global {
    my ($self, $c) = @_;

    my $form = $self->change_password_form;

    $c->stash(
        template => 'form/auth/change_password.tt',
        form     => $form,
    );
    $form->process(
        item_id => $c->user->id,
        params  => $c->request->parameters,
        schema  => $c->model('DBIC')->schema,
    );

    return if !$form->is_valid;

    $c->flash->{status_msg} = 'Password changed';
    $c->response->redirect($c->uri_for('/account'));

}

sub email_reset_password_link : Global {
    my ($self, $c) = @_;

    my $form = $self->email_reset_password_link_form;
    $c->stash(
        template => 'form/auth/reset_password.tt',
        form     => $form,
    );
    $form->process(
        params => $c->request->parameters,
        schema => $c->model('DBIC')->schema,
    );
    return if !$form->is_valid;

    # Get user based on email.
    my $to_email = $form->field('email')->value;
    my $user     = $c->model('DBIC::Player')->find({ email => $to_email });

    # create and email password reset link
    my $token = create_token($user->id);
    my $create_token_coderef = sub {
        $c->model('DBIC::Token')->create(
            {
                player => $user->id,
                token  => $token,
                type   => 'reset_password',
            }
        );
    };
    eval { $c->model('DBIC')->schema->txn_do($create_token_coderef); };
    if ($@) {
        my $message = "Not able to create token\n";
        warn $message . $@;
        $c->flash->{status_msg} = $message;
    }
    else {
        $c->forward($self->action_for('email_link'), [ $to_email, $token ]);
        $c->flash->{status_msg} =
          "A password reset </strong>link</strong> has been <strong>emailed to you.</strong>";
        $c->response->redirect($c->uri_for('/message'));
    }
}

sub reset_password : Global {
    my ($self, $c) = @_;

    my $token = $c->request->query_parameters->{reset_password_token};
    warn "TOKEN: $token\n" if debug;
    my ($user_id) = $token =~ /_(\d+)$/;
    warn "USER ID for RESET: $user_id\n" if debug;
    my $token_row_object =
      $c->model('DBIC::Token')
      ->search({ player => $user_id, token => $token, type => 'reset_password' })->first;
    if (!$token_row_object) {
        $c->response->body("Token not found.");
        $c->detach();
    }

    my $form          = $self->reset_password_form;
    my $player_object = $token_row_object->player;
    $c->stash(
        template => 'form/auth/reset_password.tt',
        form     => $form,
    );
    $form->process(
        item   => $player_object,
        params => $c->request->body_parameters,
        schema => $c->model('DBIC')->schema,
    );
    return if !$form->is_valid;

    $c->flash->{status_msg} = "Password has been reset.";
    $c->response->redirect($c->uri_for('/login'));
}

sub create_token {
    my $user_id = shift;
    return time . rand(10000) . "_${user_id}";
}

sub email_link : Private {
    my ($self, $c, $to_email, $token) = @_;

    use Email::Sender::Simple qw(try_to_sendmail);
    use Email::Simple;
    use Email::Simple::Creator;
    use Email::Sender::Transport::Test;

    my $link        = $c->request->base . 'reset_password?reset_password_token=' . $token;
    my $admin_email = 'hunter@missoula.org';
    my $subject     = 'Reset password link';
    my $message     = <<"END_MESSAGE";
Use the following link to reset your password: 
$link
END_MESSAGE

    my $email = Email::Simple->create(
        header => [
            To      => $to_email,
            From    => $admin_email,
            Subject => $subject,
        ],
        body => $message,
    );
    my $success = try_to_sendmail($email);
}

sub message : Global {
    my ($self, $c) = @_;

    $c->stash->{template} = 'empty.tt';
}

1
