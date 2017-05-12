package TestApp::Controller::Root;

use strict;
use warnings;
use parent qw/Catalyst::Controller::RateLimit Catalyst::Controller/;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(
    namespace => '',
    rate_limit => [
        {
            period =>  3600,
            max_requests => 30
        }, {
            period => 60,
            max_requests => 5
        }
    ]
);

=head1 NAME

TestApp::Controller::Root - Root Controller for TestApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 index

=cut

sub checked_page :Local :Args(0) {
    my ( $self, $c ) = @_;
    if ( $self->is_user_overrated( 'test' . $$ ) ) {
        $c->response->status( 500 );
    };
    $c->response->body( 'превед' );
}

sub protected_page :Local :Args(0) {
    my ( $self, $c ) = @_;
    if ( $self->register_attempt( 'test' . $$ ) ) {
        $c->response->status( 500 );
    };
    $c->response->body( 'превед' );
}

sub kick_robot :Local :Args(0) {
    my ( $self, $c ) = @_;
    $c->response->status( 500 );
    $c->response->body( 'ненененене' );
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
    
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Andrey Kostenko <andrey@kostenko.name>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
