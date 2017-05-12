package Bracket::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Perl6::Junction qw/ any /;
use DateTime;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Bracket::Controller::Root - Root Controller for Bracket

=head1 DESCRIPTION

Handle Security.

=head1 METHODS

=cut

=head2 auto

Make sure we're logged in when we should be.

=cut

sub auto : Private {
    my ($self, $c) = @_;

    my @open_actions = (
        $c->controller('Auth')->action_for('register'),
        $c->controller('Auth')->action_for('login'),
        $c->controller('Auth')->action_for('email_reset_password_link'),
        $c->controller('Auth')->action_for('reset_password'),
    );

    # Allow unauthenticated users to reach the open actions like 'login'.
    if ($c->action eq any(@open_actions)) {
        return 1;
    }

    # If a user doesn't exist, force login
    if (!$c->user_exists) {

        # Redirect the user to the login page
        $c->response->redirect($c->uri_for($c->controller('Auth')->action_for('login')));

        # Return 0 to cancel 'post-auto' processing and prevent use of application
        return 0;
    }
    else {

        # Stash in home page link if we're not on home page.
        if (
            ($c->action ne $c->controller('Player')->action_for('home'))
            || (   ($c->action eq $c->controller('Player')->action_for('home'))
                && ($c->req->args->[0] && ($c->req->args->[0]) != $c->user->id))
          )
        {
            $c->stash->{show_home} = 1;
        }

        # See if player is an admin to get admin only links (e.g. Perfect Player access)
        my @user_roles = $c->user->roles;
        if ('admin' eq any(@user_roles)) {
            $c->stash->{is_admin} = 1;
        }
        
        # Set cutoff state
        my $cutoff_time = $self->edit_cutoff_time($c);
        $c->stash->{is_game_time} = (DateTime->now(time_zone => $cutoff_time->time_zone) > $cutoff_time);

        # Note if we have a normal user in game time (used to hide edit links)
        $c->stash->{is_normal_user_in_game_time} =
          (!$c->stash->{is_admin} &&  $c->stash->{is_game_time});
    }

    # User found, so return 1 to continue with processing after this 'auto'
    return 1;

}

=head2 index

  Handle root index by redirecting to home when logged in.

=cut

sub index : Path : Args(0) {
    my ($self, $c) = @_;

    # Clear the user's state

    # Send the user to the starting point
    $c->go($c->controller('Player')->action_for('home'), [ $c->user->id ]);
}

=head2 default

=cut

sub default : Private {
    my ($self, $c) = @_;

    #	$c->response->body( $c->welcome_message );
    $c->go('/error_404');

}

sub error_404 : Path('error_404') : Args(0) {
    my ($self, $c) = @_;
    $c->res->status(404);

    $c->stash->{template} = 'page_not_found.tt';
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {
}

# This needs to be edited in future years to reflect the start date/time.
# TODO: Put into conf
sub edit_cutoff_time {
    my ($self, $c) = @_;

    my $cutoff = $c->config->{edit_cutoff_time};
    return DateTime->new(
        year   => $cutoff->{year},
        month  => $cutoff->{month},
        day    => $cutoff->{day},
        hour   => $cutoff->{hour},
        minute => $cutoff->{minute},
        second => $cutoff->{second},
        time_zone => $cutoff->{time_zone},
    );

}

=head1 AUTHOR

root

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
