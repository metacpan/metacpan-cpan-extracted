package CatalystX::Controller::Auth;

use 5.006;
use strict;
use warnings;

=head1 NAME

CatalystX::Controller::Auth - A config-driven Catalyst authentication controller base class.

=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';

$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;

use HTML::FormHandlerX::Form::Login;

has form_handler                         => ( is => 'ro', isa => 'Str',  default => 'HTML::FormHandlerX::Form::Login' );

has view                                 => ( is => 'ro', isa => 'Str',  default => 'TT' );

has realm                                => ( is => 'ro', isa => 'Str',  default => 'default' );

has login_fields                         => ( is => 'ro', isa => 'HashRef', default => sub { { default => [ qw(username password) ] } } );

has login_id_field                       => ( is => 'ro', isa => 'Str',  default => 'username' );
has login_id_db_field                    => ( is => 'ro', isa => 'Str',  default => 'username' );
has db_id_field                          => ( is => 'ro', isa => 'Str',  default => 'id'       );

has enable_register                      => ( is => 'ro', isa => 'Bool', default => 1 );
has enable_sending_register_email        => ( is => 'ro', isa => 'Bool', default => 1 );

has register_template                    => ( is => 'ro', isa => 'Str',  default => 'auth/register.tt'        );
has login_template                       => ( is => 'ro', isa => 'Str',  default => 'auth/login.tt'           );
has change_password_template             => ( is => 'ro', isa => 'Str',  default => 'auth/change-password.tt' );
has forgot_password_template             => ( is => 'ro', isa => 'Str',  default => 'auth/forgot-password.tt' );
has reset_password_template              => ( is => 'ro', isa => 'Str',  default => 'auth/reset-password.tt'  );

has register_successful_message          => ( is => 'ro', isa => 'Str',  default => "You are now registered."       );
has register_exists_failed_message       => ( is => 'ro', isa => 'Str',  default => "That username already exists." );
has login_required_message               => ( is => 'ro', isa => 'Str',  default => "You need to login."            );
has already_logged_in_message            => ( is => 'ro', isa => 'Str',  default => "You are already logged in."    );
has login_successful_message             => ( is => 'ro', isa => 'Str',  default => "You have logged in."           );
has logout_successful_message            => ( is => 'ro', isa => 'Str',  default => "You have been logged out."     );
has login_failed_message                 => ( is => 'ro', isa => 'Str',  default => "Bad username or password."     );
has password_changed_message             => ( is => 'ro', isa => 'Str',  default => "Password changed."             );
has password_reset_message               => ( is => 'ro', isa => 'Str',  default => "Password reset successfully."  );
has forgot_password_id_unknown           => ( is => 'ro', isa => 'Str',  default => "Email address not registered." );

has auto_login_after_register            => ( is => 'ro', isa => 'Bool', default => 1 );

has action_after_register                => ( is => 'ro', isa => 'Str',  );
has action_after_login                   => ( is => 'ro', isa => 'Str',  );
has action_after_change_password         => ( is => 'ro', isa => 'Str',  );

has email_stash_key                      => ( is => 'ro', isa => 'Str',  default => 'email_template'          );

has forgot_password_email_view           => ( is => 'ro', isa => 'Str',  default => 'Email::Template'         );
has forgot_password_email_from           => ( is => 'ro', isa => 'Str',  default => 'nobody@localhost'        );
has forgot_password_email_subject        => ( is => 'ro', isa => 'Str',  default => 'Forgot Password'         );
has forgot_password_email_template_plain => ( is => 'ro', isa => 'Str',  default => 'reset-password-plain.tt' );

has register_email_view                  => ( is => 'ro', isa => 'Str',  default => 'Email::Template'      );
has register_email_from                  => ( is => 'ro', isa => 'Str',  default => 'nobody@localhost'     );
has register_email_subject               => ( is => 'ro', isa => 'Str',  default => 'Registration Success' );
has register_email_template_plain        => ( is => 'ro', isa => 'Str',  default => 'register-plain.tt'    );

has token_salt                           => ( is => 'ro', isa => 'Str',  default => "abc123" );

BEGIN { extends 'Catalyst::Controller'; }

=head1 SYNOPSIS

This is a Catalyst controller for handling registering, logging in/out, forgotten/resetting passwords, and changing passwords.

This controller was essentially born out of L<HTML::FormHandlerX::Form::Login> (which it uses), though
that form does not want to become dependant on Catalyst.

See L<CatalystX::SimpleLogin> for an alternative approach.

Ensure you include the L<Catalyst::Plugin::StatusMessage> in MyApp.pm.

 use Catalyst qw/
    ...
    StatusMessage
    ... 
 /;
 
Extend this base controller class for your own authentication controller, then modify your config as required.

The configs for C<action_after_register>, C<action_after_login>, and C<action_after_change_password> will all need
specifying in your own config since they will be specific to your app.

 package MyApp::Controller::Auth;
 
 use Moose;
 use namespace::autoclean;
 
 BEGIN { extends 'CatalystX::Controller::Auth'; }
 
 __PACKAGE__->meta->make_immutable;
 
 1;

Configure it as you like ...

 <Controller::Auth>
 
         form_handler                           HTML::FormHandlerX::Form::Login
         
         view                                   TT
         model                                  DB::User
    
         login_id_field                         email
         login_id_db_field                      email
     
         enable_register                        1
         enable_sending_register_email          1
     
         register_template                      auth/register.tt
         login_template                         auth/login.tt
         change_password_template               auth/change-password.tt
         forgot_password_template               auth/forgot-password.tt
         reset_password_template                auth/reset-password.tt
 
         email_stash_key                        email_template

         forgot_password_email_view             Email::Template
         forgot_password_email_from             "MyApp" <somebody@example.com>
         forgot_password_email_subject          Password Reset
         forgot_password_email_template_plain   reset-password-plain.tt

         register_email_view                    Email::Template
         register_email_from                    "MyApp" <somebody@example.com>
         register_email_subject                 Registration Success
         register_email_template_plain          register-plain.tt
 
         register_successful_message            "You are now registered"
         register_exists_failed_message         "That username is already registered."
         login_required_message                 "You need to login."
         already_logged_in_message              "You are already logged in."
         login_successful_message               "Logged in!"
         logout_successful_message              "You have been logged out successfully."
         login_failed_message                   "Bad username or password."
         password_changed_message               "Password changed."
         password_reset_message                 "Password reset successfully."
         forgot_password_id_unknown             "Email address not registered." 
    
         token_salt                             'tgve546vy6yv%^$fghY56VH54& H54&%$uy^5 Y^53U&$u v5ev'
    
         auto_login_after_register              1
     
         action_after_register                  /admin/index
         action_after_login                     /admin/index
         action_after_change_password           /admin/index
 
 </Controller::Auth>

Override actions as necessary (hopefully not too much, otherwise I have not built this right).

All feedback and patches are always welcome.

=head1 CHAINS

=head2 base ( mid-point: / )

The controller currently chains/bases off C</base>, ie, the base chain in your Root controller.

 sub base :Chained('/base') :PathPart('') :CaptureArgs(0)

If you wish to chain off any other mid-point, and/or change the C<PathPart> (by default empty), you can override this action...

 sub base :Chained('/my_base') :PathPart('users') :CaptureArgs(0)
 {
         my ( $self, $c ) = @_;
 
         $self->next::method( $c );
 }
 
=cut

sub base :Chained('/base') :PathPart('') :CaptureArgs(0)
{
    my ( $self, $c ) = @_;
}

=head2 authenticated ( mid-point: / )

Chain off this action to make sure the user is logged in.

 sub authenticated :Chained('base') :PathPart('') :CaptureArgs(0)

=cut

sub authenticated :Chained('base') :PathPart('') :CaptureArgs(0)
{
    my ( $self, $c ) = @_;
    
    $self->not_authenticated( $c ) if ! $c->user_exists;
}

=head2 not_authenticated

This method is called if the user is not currently logged in.

By default it redirects (and detaches) to the URI for the C<login> action with an C<error> message of C<login_required_message>.

An instance method that is also passed the Catalyst context object C<$c>.

=cut

sub not_authenticated
{
    my ( $self, $c ) = @_;
    
    $c->response->redirect( $c->uri_for( $self->action_for('login'), { mid => $c->set_error_msg( $self->login_required_message ) } ) );
    $c->detach; 
}

=head2 register ( end-point: /register )

Register, unless the C<enable_register> option has been turned off (on by default).

If the user is already logged in, it redirects (and detaches) to the URI for C<action_after_login> with
status message C<already_logged_in_message>.

Upon registering, an attempt is made to call C<auto_create()> on your C<model> (C<DB::User> if using the default configs above).

A change is coming in May 2012 to this approach, to fallback to simply calling C<create()> if there is no C<auto_create> method in your model.

In the meantime, if you do not wish to take advantage of this hook, you will need to create the method to simply call the C<create()> method of your model...

 sub auto_create
 {
     my $self = shift;
     
     $self->create( @_ );
 }

=cut

sub register :Chained('base') :PathPart :Args(0)
{
    my ( $self, $c ) = @_;
    
    if ( ! $self->enable_register )
    {
        $c->res->redirect('/');
        $c->detach;
    }
    
    if ( $c->user_exists )
    {
        $c->response->redirect( $c->uri_for_action( $self->action_after_login, { mid => $c->set_status_msg( $self->already_logged_in_message ) } ) );
        $c->detach;
    }
    
    my $form = $self->form_handler->new( active => [ $self->login_id_field, 'password', 'confirm_password' ] );
    
    if ( $c->req->method eq 'POST' )
    {
        $form->process( params => $c->request->params );

        if ( $form->validated )
        {
            my $auth_store = $c->get_auth_realm( $self->realm )->store;

            if ( $auth_store->find_user( { $self->login_id_db_field => $form->field( $self->login_id_field )->value }, $c ) )
            {
                $c->stash( error_msg => $self->register_exists_failed_message );
            }
            else
            {
                my $user;

                if ( $auth_store->can('auto_create_user') ) 
                {
                    $user = $auth_store->auto_create_user( { $self->login_id_db_field => $form->field( $self->login_id_field )->value,
                                                             password                 => $form->field('password')->value,
                                                           }, $c
                                                         );
                }
                else
                {
                    die "Store " . ref($auth_store) . " does not support auto_create_user!";
                }

                if ( $user && $self->enable_sending_register_email )
                {
                    $self->send_register_email( $c, user => $user );
                }

                if ( $self->auto_login_after_register )
                {
                    $c->authenticate( { $self->login_id_db_field => $form->field( $self->login_id_field )->value, password => $form->field('password')->value }, $self->realm );
                }

                $self->post_register( $c );
            }
        }
    }

    $c->stash( template => $self->register_template, form => $form );
}

=head2 send_register_email

Uses C<Catalyst::View::Email::Template> by default.

An instance method that is also passed the Catalyst context object C<$c>, along with a hash of extra
parameteres, specifically the C<user> object.

=cut

sub _send_register_email
{
    my $self = shift;
    
    # legacy method here, just passing through
    
    $self->send_register_email( @_ );
    
    return $self;
}

sub send_register_email
{
    my ( $self, $c, %args ) = @_;
    
    # send registration email to the user
    
    $c->stash->{ $self->email_stash_key } = { to           => $args{ user }->get_object->email,
                                              from         => $self->register_email_from,
                                              subject      => $self->register_email_subject,
                                              content_type => 'multipart/alternative',
                                              templates => [ { template        => $self->register_email_template_plain,
                                                               content_type    => 'text/plain',
                                                               charset         => 'utf-8',
                                                               encoding        => 'quoted-printable',
                                                               view            => $self->view, 
                                                             }
                                                           ]
                                            };
    
    $c->forward( $c->view( $self->register_email_view ) );
    
    $c->stash( status_msg => "Registration email sent to " . $args{ user }->get_object->email );
    
    return $self;
}

=head2 post_register

Called after a user has successfully registered, and the register email has been sent (unless you have overridden C<send_register_email>).

An instance method that is also passed the Catalyst context object C<$c>.

By default this method redirects to the URI for C<action_after_register> with status message C<register_successful_message>.

=cut

sub post_register
{
    my ( $self, $c ) = @_;
                
    $c->response->redirect( $c->uri_for_action( $self->action_after_register, { mid => $c->set_status_msg( $self->register_successful_message ) } ) );
    $c->detach;
}

=head2 login ( end-point: /login )

Login, redirect if already logged in.

 sub login :Chained('base') :PathPart :Args(0)

=cut

sub login :Chained('base') :PathPart :Args(0)
{
    my ( $self, $c ) = @_;
    
    if ( $c->user_exists )
    {
        $c->response->redirect( $c->uri_for_action( $self->action_after_login, { mid => $c->set_status_msg( $self->already_logged_in_message ) } ) );
        return;
    }

    my $realm = $c->req->param('realm') || $self->realm;

    my $fields = $self->login_fields->{ $realm };

    if ( $c->req->param('openid-check') )
    {
        ## Returning from openid login, no fields in form for this yet
        $fields = [];
    }

    my $form = $self->form_handler->new( active => $fields );

    ## openid returns with GET params!  
    if( $c->req->param && $c->req->param > 1 ) # at least 2 as we have the "mid" param.. 
    {
        $form->process( params => $c->request->params );
    
        if ( $form->validated )
        {
            my $authinfo = { map { $_ => $form->field( $_ )->value } @$fields };
            
            if ( $c->authenticate( $authinfo, $realm ) )
            {
                if ( $c->req->params->{ remember } )
                {
                    $c->response->cookies->{ remember } = { value => $form->field( $self->login_id_field )->value };
                }
                else
                {
                    $c->response->cookies->{ remember } = { value => '' };
                }
    
                $self->post_login( $c );
            }
            else
            {
                $c->stash( error_msg => $self->login_failed_message );
            }
        }
    }
        
    $c->stash( template => $self->login_template, form => $form );
}

=head2 post_login

Called after a successfull login.

An instance method that is also passed the Catalyst context object C<$c>.

By defualt redirects (and detaches) to the URI for C<action_after_login> with a status message of C<login_successful_message>.

=cut

sub post_login
{
    my ( $self, $c ) = @_;
    
    $c->response->redirect( $c->uri_for_action( $self->action_after_login, { mid => $c->set_status_msg( $self->login_successful_message ) } ) );
    $c->detach;
}

=head2 logout ( end-point: /logout )

Logs out, and redirects back to /login.

 sub logout :Chained('base') :PathPart :Args(0)

=cut

sub logout :Chained('base') :PathPart :Args(0)
{
    my ( $self, $c ) = @_;
    
    $c->logout;
    
    $self->post_logout( $c );
}

=head2 post_logout

Called after logging out.

An instance method that is also passed the Catalyst context object C<$c>.

By default redirects (and detaches) to the URI for the C<login> action with a status message of C<logout_successful_message>.

=cut

sub post_logout
{
    my ( $self, $c ) = @_;
    
    $c->response->redirect( $c->uri_for( $self->action_for( 'login' ), { mid => $c->set_status_msg( $self->logout_successful_message ) } ) );
    $c->detach;
}

=head2 forgot_password ( end-point: /forgot-password/ )

Send a forgotten password token to reset it.  This method uses the built-in features from L<HTML::FormHandlerX::Form::Login> for handling the token, etc.

 sub forgot_password :Chained('base') :PathPart('forgot-password') :Args(0)

=cut

sub forgot_password :Chained('base') :PathPart('forgot-password') :Args(0)
{
    my ( $self, $c ) = @_;
    
    my $form = $self->form_handler->new( active => [ qw( email ) ] );
    
    if ( $c->req->method eq 'POST' )
    {
        $form->process( params => $c->request->params );
    
        if ( $form->validated )
        {
            my $user = $c->get_auth_realm($self->realm)->store->find_user( { $self->login_id_db_field => $c->request->params->{ $self->login_id_field } }, $c );
        
            if ( $user )
            {
                $c->stash( user => $user );
                
                $form->token_salt( $self->token_salt );
        
                $form->add_token_field( $self->login_id_field );
        
                my $token = $form->token;
        
                $c->stash( token => $token );
        
                $self->_send_password_reset_email( $c, user => $user );
            }
            else
            {
                $c->stash( error_msg => $self->forgot_password_id_unknown );
            }
        }
    }
    
    $c->stash( template => $self->forgot_password_template, form => $form );
}

=head2 send_password_reset_email

Uses C<Catalyst::View::Email::Template> by default.

An instance method that is also passed the Catalyst context object C<$c>, along with a hash of extra
parameteres, specifically the C<user> object.

=cut

sub _send_password_reset_email
{
    my $self = shift;
    
    # legacy method here, just passing through
    
    $self->send_password_reset_email( @_ );
    
    return $self;
}
    
sub send_password_reset_email
{
    my ( $self, $c, %args ) = @_;
    
    # send reset password username to the user
    
    $c->stash->{ $self->email_stash_key } = { to           => $args{ user }->get_object->email,
                                              from         => $self->forgot_password_email_from,
                                              subject      => $self->forgot_password_email_subject,
                                              content_type => 'multipart/alternative',
                                              templates => [ { template        => $self->forgot_password_email_template_plain,
                                                               content_type    => 'text/plain',
                                                               charset         => 'utf-8',
                                                               encoding        => 'quoted-printable',
                                                               view            => $self->view, 
                                                             }
                                                           ]
                                            };
    
    $c->forward( $c->view( $self->forgot_password_email_view ) );
    
    $c->stash( status_msg => "Password reset link sent to " . $args{ user }->get_object->email );
    
    return $self;
}

=head2 reset_password ( end-point: /reset-password/ )

Reset password using a token sent in an email.

 sub reset_password :Chained('base') :PathPart('reset-password') :Args(0)

=cut

sub reset_password :Chained('base') :PathPart('reset-password') :Args(0)
{
    my ( $self, $c ) = @_;
    
    if ( $c->req->method eq 'GET' && ! $c->request->params->{ token } )
    {
        $c->response->redirect( $c->uri_for( $self->action_for('forgot_password'), { mid => $c->set_status_msg("Missing token") } ) );
        return;
    }
    
    my $form;
    
    if ( $c->req->method eq 'GET' )
    {
        $form = $self->form_handler->new( active => [ qw( token password confirm_password ) ] );
    
        $form->token_salt( $self->token_salt );
    
        $form->add_token_field( $self->login_id_field );
    
        $form->process( params => { token => $c->request->params->{ token }, password => '-', confirm_password => '-' } );   # will be cleared on render since they're password fields
    
        if ( ! $form->validated )
        {
            $c->response->redirect( $c->uri_for( $self->action_for('forgot_password'), { mid => $c->set_error_msg("Invalid token") } ) );
            return;
        }
    }
    
    if ( $c->req->method eq 'POST' )
    {
        $form = $self->form_handler->new( active => [ qw( token password confirm_password ) ] );
        
        $form->token_salt( $self->token_salt );
        
        $form->add_token_field( $self->login_id_field );
        
        $form->process( params => $c->request->params );
        
        if ( $form->validated )
        {
            my $user = $c->get_auth_realm($self->realm)->store->find_user( { $self->login_id_db_field => $form->field( $self->login_id_field )->value }, $c );
            
            $user->password( $form->field('password')->value );
            
            $user->update;  
            
            $self->post_reset_password( $c );
        }
    }
    
    $c->stash( template => $self->reset_password_template, form => $form );
}

=head2 post_reset_password

After successfully resetting a users password.

An instance method that is also passed the Catalyst context object C<$c>.

By default redirects (and detaches) to the URI for the C<login> action with a status message of C<password_reset_message>.

=cut

sub post_reset_password
{
    my ( $self, $c ) = @_;
    
    $c->response->redirect( $c->uri_for( $self->action_for('login'), { mid => $c->set_status_msg( $self->password_reset_message ) } ) );
    $c->detach;
}

=head2 get ( mid-point: /auth/*/ )

Get a user (by capturing the ID) and puts them in the stash.

If no matching user is found, redirects to the URI for the C<login> action.

 sub get :Chained('base') :PathPart('auth') :CaptureArgs(1)

=cut

sub get :Chained('base') :PathPart('auth') :CaptureArgs(1)
{
    my ( $self, $c, $id ) = @_;

    my $auth_store = $c->get_auth_realm( $self->realm )->store;

    my $user = $auth_store->find_user( { $self->db_id_field => $id }, $c );

    if ( ! $user )
    {
        $c->response->redirect( $c->uri_for( $self->action_for('login'), { mid => $c->set_status_msg( $self->login_required_message ) } ) );
        $c->detach;
    }
    
    $c->stash( user => $user );
}

=head2 change_password ( end-point: /auth/*/change-password/ )

Change your password.

 sub change_password :Chained('get') :PathPart('change-password') :Args(0)

=cut

sub change_password :Chained('get') :PathPart('change-password') :Args(0)
{
    my ( $self, $c ) = @_;
    
    my $form = $self->form_handler->new( active => [ qw( old_password password confirm_password ) ] );
    
    if ( $c->req->method eq 'POST' )
    {
        $form->process( params => $c->request->params );
        
        if ( $form->validated )
        {
            my $user = $c->stash->{ user };
            
            if ( ! $c->authenticate( { $self->login_id_db_field => $user->get_object->email, password => $form->field('old_password')->value }, $self->realm ) )
            {
                $c->stash( error_msg => 'Old password incorrect' );
            }
            else
            {
                $user->password( $form->field('password')->value );
            
                $user->update;  
            
                $self->post_change_password( $c );
            }
        }
    }
    
    $c->stash( template => $self->change_password_template, form => $form );
}

=head2 post_change_password

After changing a password.

An instance method that is also passed the Catalyst context object C<$c>.

By default redirects (and detaches) to the URI for C<action_after_change_password> with status message C<password_changed_message>.

=cut

sub post_change_password
{
    my ( $self, $c ) = @_;
                
    $c->response->redirect( $c->uri_for_action( $self->action_after_change_password, { mid => $c->set_status_msg( $self->password_changed_message ) } ) );
    $c->detach;
}

=head1 TODO

Damn more tests!


=head1 AUTHOR

Rob Brown, C<< <rob at intelcompute.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalystx-controller-auth at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-Controller-Auth>.  I will be notified, and then you will
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::Controller::Auth


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-Controller-Auth>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-Controller-Auth>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-Controller-Auth>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-Controller-Auth/>

=back

=head1 ACKNOWLEDGEMENTS

t0m: Tomas Doran E<lt>bobtfish@bobtfish.netE<gt>

castaway: Jess Robinson (OpenID support)


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CatalystX::Controller::Auth
