package Catalyst::Plugin::MapComponentDependencies::Utils;

use Scalar::Util 'blessed';
use Exporter 'import';
use Catalyst::Utils;

our @EXPORT_OK = (qw/FromModel FromView FromController
  FromComponent FromCode ConfigLoaderSubstitutions
  FromContext FromRequest FromResponse FromLog
  FromApplication/);

our %EXPORT_TAGS = (All => \@EXPORT_OK, ALL => \@EXPORT_OK);

sub model_ns {  __PACKAGE__ .'::MODEL' }
sub view_ns {  __PACKAGE__ .'::VIEW' }
sub controller_ns {  __PACKAGE__ .'::CONTROLLER' }
sub component_ns {  __PACKAGE__ .'::COMPONENT' }
sub code_ns {  __PACKAGE__ .'::CODE' }

sub _is {
  my ($possible, $target_ns) = @_;
  return (defined($possible) and
    blessed($possible) and 
      $possible->isa($target_ns)) ?
        $$possible : 0;
}

sub is_model($) { return _is(shift, model_ns) }
sub is_view($) { return _is(shift, view_ns) }
sub is_controller($) { return _is(shift, controller_ns) }
sub is_component($) { return _is(shift, component_ns) }
sub is_code($) { return _is(shift, code_ns) }

sub FromModel($) { my $v = shift; return bless \$v, model_ns }
sub FromView($) { my $v = shift; return bless \$v, view_ns }
sub FromController($) { my $v = shift; return bless \$v, controller_ns }
sub FromComponent($) { my $v = shift; return bless \$v, component_ns }
sub FromCode(&) { my $v = shift; return bless \$v, code_ns }

sub FromContext {
  return FromCode {
    my ($c, $name, $config) = @_;
    return blessed $c ? $c : undef;
  };
}

sub FromRequest {
  return FromCode {
    my ($c, $name, $config) = @_;
    return blessed $c ? $c->request : undef;
  };
}

sub FromResponse {
  return FromCode {
    my ($c, $name, $config) = @_;
    return blessed $c ? $c->response : undef;
  };
}

sub FromLog {
  return FromCode {
    my ($c_or_app, $name, $config) = @_;
    return $c->log; # log is application and context
  };
}

sub FromApplication {
  return FromCode {
    my ($c_or_app, $name, $config) = @_;
    return blessed $c_or_app ? ref($c_or_app): $c_or_app;
  };
}

sub _expand_config {
  my ($app_or_ctx, $component_name, $config) = @_;

  my $mapped_config = +{}; # shallow clone... might need something better than all this later
  foreach my $key (keys %$config) {
    my $value = $config->{$key};
    if(my $m = is_model $value) {
      $mapped_config->{$key} = $app_or_ctx->model($m) || die "$m is not a Model";
    } elsif(my $v = is_view $value) {
      $mapped_config->{$key} = $app_or_ctx->view($v) || die "$v is not a View";
    } elsif(my $c = is_controller $value) {
      $mapped_config->{$key} = $app_or_ctx->controller($c) || die "$c is not a Controller";
    } elsif(my $c = is_component $value) {
      $mapped_config->{$key} = $app_or_ctx->component($c) || die "$c is not a Component";
    } elsif(my $cb = is_code $value) {
      $mapped_config->{$key} = $cb->($app_or_ctx, $component_name, $config);
    }
  }

  return my $merged = Catalyst::Utils::merge_hashes($config, $mapped_config);
}

sub ConfigLoaderSubstitutions {
  return (
    FromContext => sub { my $c = shift; FromContext },
    FromRequest => sub { my $c = shift; FromRequest },
    FromResponse => sub { my $c = shift; FromResponse },
    FromLog => sub { my $c = shift; FromLog },
    FromApplication => sub { my $c = shift; FromApplication },
    FromModel => sub { my $c = shift; FromModel(@_) },
    FromView => sub { my $c = shift; FromView(@_) },
    FromController => sub { my $c = shift; FromController(@_) },
    FromComponent => sub { my $c = shift; FromComponent(@_) },
    FromCode => sub {
      my $c = shift;
      FromCode { eval shift };
    },
  );
}

1;

=head1 NAME

Catalyst::Plugin::MapComponentDependencies::Utils - Utilities to integrate dependencies

=head1 SYNOPSIS

    package MyApp;

    use Moose;
    use Catalyst 'MapComponentDependencies;
    use Catalyst::Plugin::MapComponentDependencies::Utils ':All';

    MyApp->config(
      'Model::Bar' => { key => 'value' },
      'Model::Foo' => {
        bar => FromModel 'Bar',
        baz => FromCode {
          my ($app_or_ctx, $component_name) = @_;
          return ...;
        },
        another_param => 'value',
      },
    );

    MyApp->setup;

=head1 DESCRIPTION

Utility functions to streamline integration of dynamic dependencies into your
global L<Catalyst> configuration.

L<Catalyst::Plugin::MapComponentDependencies> offers a simple way to specify
configuration values for you components to be the value of other components
and to do so in a way that respects if your component does ACCEPT_CONTEXT.
We do this by providing a new namespace key in your configuration.  However
you may prefer a 'flatter' configuration.  These utility methods allow you to
'tag' a value in your configuration.  This leads to a more simple configuration
setup, but it has the downside in that you must either use a Perl configuration
(as in the SYNOPSIS example) or if you are using L<Catalyst::Plugin::ConfigLoader>
you can install additional configuration substitutions like so:

    use Catalyst::Plugin::MapComponentDependencies::Utils ':All';

    __PACKAGE__->config->{ 'Plugin::ConfigLoader' }
      ->{ substitutions } = { ConfigLoaderSubstitutions };

See L<Catalyst::Plugin::MapComponentDependencies> for other options to declare
your component dependencies if this approach does not appeal.

=head1 EXPORTS

This package exports the following functions

=head2 FromModel

Creates a dependency to the named model.

=head2 FromView

Creates a dependency to the named model.

=head2 FromController

Creates a dependency to the named controller.

=head2 FromCode

An anonymouse coderef that must return the expected dependency.

=head2 FromContext

The current context, or undefined if the model does not ACCEPT_CONTEXT.

B<NOTE>: Its really easy to create a circular reference when using the
context as a dependency.  I recommend making sure the object which is
consuming it stores a weak reference.  For example:

    package MyApp::Object;

    use Moose;

    has ctx => (is=>'ro', required=>1, weak_ref=>1);

    # rest of code...

=head2 FromRequest

The current L<Catalyst::Request> instance, or undefined if the model does not
ACCEPT_CONTEXT.

=head2 FromResponse

The current L<Catalyst::Response> instance, or undefined if the model does not
ACCEPT_CONTEXT.

=head2 FromLog

The current Log object.

=head2 FromApplication

You application class.

=head2 ConfigLoaderSubstitutions

Returns a Hash suitable for use as additional substitutions in
L<Catalyst::Plugin::ConfigLoader>.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::MapComponentDependencies>,
L<Catalyst::Plugin::ConfigLoader>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
