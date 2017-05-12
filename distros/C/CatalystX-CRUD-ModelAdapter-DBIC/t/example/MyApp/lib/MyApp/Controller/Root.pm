package MyApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

MyApp::Controller::Root - Root Controller for MyApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub default : Path {
    my ( $self, $c ) = @_;

}

=head2 end

Attempt to render a view, if needed.

=cut 

sub render_end : ActionClass('RenderView') {
}

sub end : Private {
    my ( $self, $c ) = @_;
    if ( @{ $c->error } ) {

        $c->log->error($_) for @{ $c->error };

        if ( grep {m/can't create new/} @{ $c->error } ) {
            $c->error404;
            $c->clear_errors;
            return;
        }

    }
    $c->forward('render_end');
}

=head1 AUTHOR

Peter Karman

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
