package App::AutoCRUD::Controller::Gvascript;

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::Controller';

use Alien::GvaScript;
use namespace::clean -except => 'meta';

sub serve {
  my ($self) = @_;

  my $context = $self->context;
  my $path    = $context->path;
  my $file    = Alien::GvaScript->path . "/" . $context->path;
  -f $file
    or die "GvaScript $path: not found";

  my $view_class = $context->app->find_class("View::Download")
    or die "no Download view";
  $context->set_view($view_class->new);

  return $file;
}

1;


__END__

=head1 NAME

App::AutoCRUD::Controller::GvaScript

=head1 DESCRIPTION

Controller for returning L<Alien::GvaScript> components.

=head1 METHODS

=head2 serve

Finds the requested GvaScript file from the URL path, and returns
that file through the L<App::AutoCRUD::View::Download> view.

