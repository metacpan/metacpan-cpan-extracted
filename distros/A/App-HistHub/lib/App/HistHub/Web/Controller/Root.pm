package App::HistHub::Web::Controller::Root;
use strict;
use warnings;
use parent 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

=head1 NAME

App::HistHub::Web::Controller::Root - Root Controller for App::HistHub::Web

=head1 DESCRIPTION

L<App::HistHub>.

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->view('TD')->template('index');
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

Daisuke Murase

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
