package TestApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

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

sub default : Private {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

sub model : Local {
    my ($self, $c, $model_name) = @_;
    $c->res->body($c->model($model_name));
}

sub model_got_dbh : Local {
    my ($self, $c, $model_name) = @_;
    $c->res->body(ref $c->model('DM')->dbh);
}

=head1 AUTHOR

Cedric Bouvier,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
