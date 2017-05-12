package Catalyst::Plugin::URI;

use Moo::Role;
use Scalar::Util ();

requires 'uri_for';

our $VERSION = '0.002';

sub uri {
  my ($c, $path, @args) = @_;

  # already is an $action
  if(Scalar::Util::blessed($path) && $path->isa('Catalyst::Action')) {
    return $c->uri_for($path, @args);
  }

  # Hard error if the spec looks wrong...
  die "$path is not a string" unless ref \$path eq 'SCALAR';
  die "$path is not a controller.action specification" unless $path=~m/^(.*)\.(.+)$/;

  die "$1 is not a controller"
    unless my $controller = $c->controller($1||'');

  die "$2 is not an action for controller ${\$controller->component_name}"
    unless my $action = $controller->action_for($2);

  return $c->uri_for($action, @args);
}


1;

=head1 NAME

Catalyst::Plugin::URI - Yet another sugar plugin for $c->uri_for

=head1 SYNOPSIS

Use the plugin in your application class:

    package MyApp;
    use Catalyst 'URI';

    MyApp->setup;

Then you can use it in your controllers:

    package MyApp::Controller::Example;

    use base 'Catalyst::Controller';

    sub make_a_url :Local {
      my ($self, $c) = @_;
      my $url = $c->uri("$controller.$action", \@args, \%query, \$fragment);
    }

This is just a shortcut with stronger error messages for:

    sub make_a_url :Local {
      my ($self, $c) = @_;
      my $url = $c->url_for(
        $c->controller($controller)->action_for($action),
          \@args, \%query, \$fragment);
    }

=head1 DESCRIPTION

Currently if you want to create a URL to a controller's action properly the formal
syntax is rather verbose:

    my $url = $c->uri(
      $c->controller($controller)->action_for($action),
        \@args, \%query, \$fragment);


Which is verbose enough that i probably encourages people to do the wrong thing
and use a hard coded link path.  This might later bite you if you need to change
your controllers and URL hierarchy.

Also, this can lead to weird error messages that don't make if clear that your
$controller and $action are actually wrong.  This plugin is an attempt to both
make the proper formal syntax a bit more tidy and to deliver harder error messages
if you get the names wrong.

=head1 METHODS

This plugin adds the following methods to your context

=head2 uri

Example:

    $c->uri("$controller.$action", \@parts, \%query, \$fragment);

This is a sugar method which works the same as:

    my $url = $c->uri_for(
      $c->controller($controller)->action_for($action),
        \@args, \%query, \$fragment);

Just a bit shorter, and also we check to make sure the $controller and
$action actually exist (and raise a hard fail if they don't with an error
message that is I think more clear than the longer version.

You can also use a 'relative' specification for the action, which assumes
the current controller.  For example:

    $c->uri(".$action", \@parts, \%query, \$fragment);

Basically the same as:

    my $url = $c->uri_for(
      $self->action_for($action),
        \@args, \%query, \$fragment);

Lastly For ease of use if the first argument is an action object we just pass it
down to 'uri_for'.  That way you should be able to use this method for all types
of URL creation.

=head1 OTHER SIMILAR OPTIONS

L<Catalyst> offers a second way to make URLs that use the action private
name, the 'uri_for_action' method.  However this suffers from a bug where
'path/action' and '/path/action' work the same (no support for relative
actions).  Also this doesn't give you a very good error message if the action
private path does not exist, leading to difficult debugging issues sometimes.
Lastly I just personally prefer to look up an action via $controller->action_for(...)
over the private path, which is somewhat dependent on controller namespace
information that you might change.

Prior art on CPAN doesn't seem to solve issues that I think actually exist (
for example older versions of L<Catalyst> required that you specify capture
args from args in a Chained action, there's plugins to address that but that
was fixed in core L<Catalyst> quite a while ago.)  This plugin exists merely as
sugar over the formal syntax and tries to do nothing else fancy.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>

=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut
