package Catalyst::View::Template::Lace::Role::URI;

use Moo::Role;
use Scalar::Util;

sub uri_for { shift->ctx->uri_for(@_) }

sub action_for { shift->ctx->controller->action_for(@_) }

sub uri {
  my ($self, $action_proto, @args) = @_;

  # If its already an action object just use it.
  return $self->ctx->uri_for($action_proto, @args)
    if Scalar::Util::blessed($action_proto); 

  my $controller = $self->ctx->controller;
  my $action;

  # Otherwise its a string which is a full or relative path
  # to the private name of an action.  Resolve it.
  # Starts with '/' means its a full absolute private name
  # Otherwise its a realtive name to the current controller
  # namespace.

  if($action_proto =~/\//) {
    my $path = $action_proto=~m/^\// ? $action_proto : $controller->action_for($action_proto)->private_path;
    die "$action_proto is not an action for controller ${\$controller->catalyst_component_name}" unless $path;
    die "$path is not a private path" unless $action = $self->ctx->dispatcher->get_action_by_path($path);
  } else {
    die "$action_proto is not an action for controller ${\$controller->catalyst_component_name}"
      unless $action = $controller->action_for($action_proto);
  }
  die "Could not create a URI from '$action_proto' with the given arguments" unless $action;
  return $self->ctx->uri_for($action, @args);
}

1;

=head1 NAME

Catalyst::View::Template::Lace::Role::URI - Shortcut to create a URI on the current controller

=head1 SYNOPSIS

    package  MyApp::View::User;

    use Moo;
    use Template::Lace::Utils 'mk_component';
    extends 'Catalyst::View::Template::Lace';
    with 'Template::Lace::ModelRole',
      'Catalyst::View::Template::Lace::Role::URI';

    sub template {q[
      <html>
        <head>
          <title>Link Example</title>
        </head>
        <body>
         <a>Link</a>
        </body>
      </html>
    ]}

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->at('a')
       ->href($self->uri('../display));
    }

=head1 DESCRIPTION

A role that gives your model object a C<uri> method.  This method works
similarly to "$c->uri_for" except that it only takes an action object or
a string that is an absolute or relative (to the current controller) private
name.

=head1 METHOD

This role defines the following methods

=head2 uri

    $self->uri($action);
    $self->uri('/user/display');
    $self->uri('display');
    $self->uri('../list');

First argument is an action object or a string.  If a string it must be either
an absolute private name to an action or a relative one

=head1 SEE ALSO
 
L<Catalyst::View::Template::Lace>.

=head1 AUTHOR

Please See L<Catalyst::View::Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Catalyst::View::Template::Lace> for copyright and license information.

=cut
