package App::AutoCRUD::Controller::Home;

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::Controller';
use namespace::clean -except => 'meta';

sub serve {
  my ($self) = @_;

  $self->context->set_template("home.tt");

  return $self->app->datasources;
}

1;

__END__

=head1 NAME

App::AutoCRUD::Controller::Home

=head1 DESCRIPTION

Controller for the homepage of the AutoCRUD application.

=head1 METHODS

=head2 serve

Finds the list of available datasources through the
L<App::AutoCRUD/datasources> method, and displays
that list through the C<home.tt> template in
L<App::View::TT> view.

