package MyApp::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} = "menu.tt";

    # Throw a couple things in there for the menu to read vars-wise.
    $c->stash->{foo} = "bar";

    return 1;
}

sub default :Path {
  my ( $self, $c ) = @_;
  # Do nothing
}

sub answer :Path('/one/answer') {
  my ( $self, $c ) = @_;
  $c->stash->{the_answer} = 42;
}

sub end : ActionClass('RenderView') {
  my ( $self, $c ) = @_;
  $c->stash->{menu} = $c->model('Menu')->get_menu;
}

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
