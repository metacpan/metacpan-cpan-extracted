package TestApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Data::Dumper;
#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

TestApp::Controller::Root - Root Controller for TestApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub test_static : Local {
    my ( $s , $c  ) = @_;
    
    $c->form(
        required => [qw/neko inu/]
    );

    if( $c->has_dfv_error ) {
        $c->response->body( 'Invalid' . Dumper ( $c->stash->{invalid} ) .  'Missing' . Dumper( $c->stash->{missing} ) );
    }
    else {
        $c->response->body( 'ok' );
    }

}

sub test_regexp : Local {
    my ( $s , $c ) = @_;

    $c->form(
        required => [qw/user_id member_id panda_neko/]
    );
    
    if( $c->has_dfv_error ) {
        $c->response->body( 'Invalid' . Dumper ( $c->stash->{invalid} ) .  'Missing' . Dumper( $c->stash->{missing} ) );
    }
    else {
        $c->response->body( 'ok' );
    }

}

sub test_strict : Local {
    my ( $self, $c ) = @_;
    $c->form(
        required => [qw/osaka kyoto hyogo/],
    );

    if( $c->has_dfv_error ) {
        $c->response->body( Dumper ( $c->stash->{invalid} ) . Dumper( $c->stash->{missing} ) );
    }
    else {
        $c->response->body( 'ok' );
    }
}

sub test_loose : Local {
    my ( $self, $c ) = @_;
    $c->form(
        required             => [qw/hyogo kyoto osaka/],
        constraints_loose    => [qw/hyogo kyoto/],
    );

    if( $c->has_dfv_error ) {
        $c->response->body( Dumper ( $c->stash->{invalid} ) . Dumper( $c->stash->{missing} ) );
    }
    else {
        $c->response->body( 'ok' );
    }
}

sub test_custom_param : Local {
    my ( $self, $c ) = @_;

    $c->form(
        custom_parameters => {
            hyogo => 'hyogo',
            kyoto => 'kinkakuji',
            osaka => 3 ,
            user_id => 343,
        },
        required    => [qw/hyogo kyoto osaka user_id/],
    );

    if( $c->has_dfv_error ) {
        $c->response->body( 'Invalid' . Dumper ( $c->stash->{invalid} ) .  'Missing' . Dumper( $c->stash->{missing} ) );
    }
    else {
        $c->response->body( 'ok' );
    }

}

=head2 end

Attempt to render a view, if needed.

=cut 

#sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Tomohiro Teranishi

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
