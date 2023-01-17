package Catalyst::Plugin::RedirectTo;

use Moose::Role;
use Carp;

requires 'response', 'uri_for', 'uri_for_action';

our $VERSION = '0.004';
our $DEFAULT_REDIRECT_STATUS = 303;

sub _default_redirect_status { return $DEFAULT_REDIRECT_STATUS }

my $normalize_status = sub {
  my $c = shift;
  my @args = @_;
  my $code = ref($args[-1]) eq 'SCALAR' ?
    ${ pop @args } : $c->_default_redirect_status;

  die "$code is not a redirect HTTP status" unless $code =~m/^3\d\d$/;

  return ($code, @args);
};

sub redirect_to {
  my $c = shift;
  my ($code, @args) = $normalize_status->($c, @_);
  my $url = $c->uri_for(@args);
  carp "Could not create a URI from the given arguments" unless $url;
  $c->response->redirect($url, $code);
}

sub redirect_to_action {
  my $c = shift;
  my ($code, $action_proto, @args) = $normalize_status->($c, @_);

  # If its already an action object just use it.
  if(Scalar::Util::blessed($action_proto)) {
    my $url = $c->uri_for($action_proto, @args);
    carp "Could not create a URI from '$action_proto' with the given arguments" unless $url;
    $c->response->redirect($url, $code);
    return $url;
  }

  my $url;
  if($c->can('uri')) {
    $url = $c->uri($action_proto, @args);
  } else {
    my $controller = $c->controller;
    my $action;
    if($action_proto =~/\//) {
      my $path = $action_proto=~m/^\// ? $action_proto : $controller->action_for($action_proto)->private_path;
      carp "$action_proto is not an action for controller ${\$controller->catalyst_component_name}" unless $path;
      carp "$path is not a private path" unless $action = $c->dispatcher->get_action_by_path($path);
    } else {
      carp "$action_proto is not an action for controller ${\$controller->catalyst_component_name}"
        unless $action = $controller->action_for($action_proto);
    }
    carp "Could not create a URI from '$action_proto' with the given arguments" unless $action;
    $url = $c->uri_for($action, @args);
    carp "Could not create a URI from '$action_proto' with the given arguments" unless $url;
  }
  $c->response->redirect($url, $code);
  return $url;
}

1;

=head1 NAME

Catalyst::Plugin::RedirectTo - Easier redirects to action objects or private paths.

=head1 SYNOPSIS

Use the plugin in your application class:

    package MyApp;
    use Catalyst 'RedirectTo';

    MyApp->setup;

Then you can use it in your controllers:

    package MyApp::Controller::Example;

    use base 'Catalyst::Controller';

    sub does_redirect_to :Local {
      my ($self, $c) = @_;
      $c->redirect_to( $self->action_for('target'), [100] );
    }

    sub does_redirect_to_action :Local {
      my ($self, $c) = @_;
      $c->redirect_to_action( 'target', [100] );
    }

    sub target :Local Args(1) {
      my ($self, $c, $id) = @_;
      $c->response->content_type('text/plain');
      $c->response->body("This is the target action for $id");
    }

=head1 DESCRIPTION

Currently if you want to setup a redirect in L<Catalyst> to an existing action the
proper form is somewhat verbose:

    $c->response->redirect(
      $c->uri_for(
        $c->controller(...)->action_for(...), \@args, \%q
      )
    );

Which is verbose enough that i probably encourages people to do the wrong thing
and use a hard coded link path in the redirect request.  This might later bite
you if you need to change your controllers and URL hierarchy.

Also, for historical reasons the default redirect code is 302, which is considered
a temporary redirect, rather than 303 which is a better default for the common use
case of a form POST that generates a new resource.  Which means to do the right
thing you really need:

    $c->response->redirect(
      $c->uri_for(
        $c->controller(...)->action_for(...), \@args, \%q
      ),
      303
    );

This plugin seeks to relieve some of the effort involved in doing the right thing.
It does this by creating a context method which encapulates the redirect response
setup (and sets a 303 by default, since that is the common case today) with a call
to 'uri_for' (or 'uri_for_action').  So instead of the above you can just do:

    $c->redirect_to($c->controller(...)->action_for(...), \@args, \%q);

or even:

    $c->redirect_to_action('controller/action', \@args, \%q);

Which hopefully is a good encapsulation of 'the right thing to do'!

B<NOTE:> Please be aware that setting up a redirect does not automatically detach or
complete the action.  You still should either return the redirect or call 'detach'
if you want to stop action processing.

=head1 METHODS

This plugin adds the following methods to your context

=head2 redirect_to ($action_obj, \@args, \%query, \$code)

Example:

    $c->redirect_to( $action_obj, \@args, \%query, \$code);

Is shorthand for:

    $c->response->redirect(
      $c->uri_for( $action_obj, \@args, \%query), $code);

$code will default to 303 (not 302 as does $c->res->redirect) as this is commonly
supported in modern browsers, so unless you have a specific need for an alternative
response code, you should be able to just leave it off.

For example:

  $c->redirect_to($self->action_for($action_name), \@args);

Basically all the arguments to this method will be sent to ->uri_for, unless the
last argument is a scalar ref, in which case it will be used to set the HTTP status
code.  $code must be '3xx' (a valid current or future redirect status).

Does not detach or return the current action (just like the existing method)!

B<NOTE:> Please notice that if you want to set a status code other than 303, that
code must be added to the argument list as a scalar ref.  This is needed to
distinguish from an argument that gets passed to 'uri_for'.

=head2 redirect_to_action

Same as 'redirect_to' but submits the arguments to 'uri_for_action' instead.  Please
B<NOTE> that if you also install L<Catalyst::Plugin::URI> we will use that for
action resolution (supports named Actions).

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::Response>

=head1 COPYRIGHT & LICENSE
 
Copyright 2018, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut
