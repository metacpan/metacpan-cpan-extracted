package Catalyst::Plugin::MapComponentDependencies;

use Moose::Role;
use Catalyst::Utils;
use Catalyst::Plugin::MapComponentDependencies::Utils;

requires 'config_for', 'component';

our $VERSION = '0.009';

# Allow a shorthand version of config, should make it a bit
# more tidy and I doubt we will ever need configuration for
# the plugin itself.

my $plugin_config = sub {
  my $config_namespace = shift->config->{'Plugin::MapComponentDependencies'} ||= +{};
  return exists $config_namespace->{map_dependencies} ?
    $config_namespace->{map_dependencies} :
      $config_namespace;
};

sub map_dependency {
  my ($self, $name, $args) = @_;
  die "Component $name exists" if
    $self->$plugin_config->{$name};
  $self->$plugin_config->{$name} = $args;
}
 
sub map_dependencies {
  my $self = shift;
  while(@_) {
    $self->map_dependency(shift, shift);
  }

  return $self->$plugin_config;
}

around 'config_for', sub {
  my ($orig, $app_or_ctx, $component_name, @args) = @_;
  my $config = $app_or_ctx->$orig($component_name, @args);
  my $component_suffix = Catalyst::Utils::class2classsuffix($component_name);

  # Walk the values and expand as needed
  $config = Catalyst::Plugin::MapComponentDependencies::Utils::_expand_config($app_or_ctx, $component_name, $config);

  if(my $dependencies = $app_or_ctx->map_dependencies->{$component_suffix}) {
    # walk the value tree for $dependencies.
    my $mapped_config = +{}; # shallow clone... might need something better than all this later
    foreach my $key (keys %$dependencies) {
      if((ref($dependencies->{$key}) ||'') eq 'CODE') {
        $mapped_config->{$key} = $dependencies->{$key}->($app_or_ctx, $component_name, $config);
      } else {
        $mapped_config->{$key} = $app_or_ctx->component($dependencies->{$key}) ||
          die "'${\$dependencies->{$key}}' is not a component...";
      }
    }

    return my $merged = Catalyst::Utils::merge_hashes($config, $mapped_config);
  } else {
    return $config;
  }  
};

1;

=head1 NAME

Catalyst::Plugin::MapComponentDependencies - Allow components to depend on other components

=head1 SYNOPSIS

    package MyApp;

    use Moose;
    use Catalyst;

    with 'Catalyst::Plugin::MapComponentDependencies';

    MyApp->map_dependencies(
      'Model::Foo' => {
        bar => 'Model::Bar',
        baz => sub {
          my ($app_or_ctx, $component_name) = @_;
          return ...;
        },
      },
    );

    MyApp->config(
      'Model::Foo' => { another_param => 'value' }
    )

    MyApp->setup;

During setup when 'Model::Foo' is created it will get all three key / value pairs
send to ->new.

B<NOTE:> You need to compose this plugin via the L<Moose> 'with' subroutine if you
want to get the handy class methods 'map_dependencies' and 'map_dependency'.  If you
prefer you may setup you dependencies via configuration:

    package MyApp;

    use Catalyst 'MapComponentDependencies';

    MyApp->config(
      'Model::Foo' => { another_param => 'value' },
      'Plugin::MapComponentDependencies' => {
        map_dependencies => {
          'Model::Foo' => {
            bar => 'Model::Bar',
            baz => sub {
              my ($app_or_ctx, $component_name, $from_config_args) = @_;
              return ...;
            },
          },
        },
      },
    );

    MyApp->setup;

Alternatively you may choose a 'shorthand' version of the configuration based
approach:

    package MyApp;

    use Catalyst 'MapComponentDependencies';

    MyApp->config(
      'Model::Foo' => { another_param => 'value' },
      'Plugin::MapComponentDependencies' => {
        'Model::Foo' => {
          bar => 'Model::Bar',
          baz => sub {
            my ($app_or_ctx, $component_name, $from_config_args) = @_;
            return ...;
          },
        },
      },
    );

    MyApp->setup;

You may prefer this if your dependencies will map differently based on environment
and configuration settings.

Lastly you may use the helper utilities to create a single merged configuration
for your dependencies:

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

See L<Catalyst::Plugin::MapComponentDependencies::Utils> for more.

=head1 DESCRIPTION

Sometimes you would like a L<Catalyst> component to depend on the value of an
existing component.  Since components are resolved during application setup (or
at request time, in the cause of a component that does ACCEPT_CONTEXT) you cannot
specify this dependency mapping in the 'normal' L<Catalyst> configuration hash.

This plugin, which requires a recent L<Catalyst> of version 5.90090+, allows you to
define components which depend on each other.  You can also set the value of an
initial argument to the value of a coderef, for added dynamic flexibility.

You may define dependencies in one of two ways.  The first way is to use a key/value
pair to map a configuation key attribute to the value of an existing L<Catalyst>
model.  When the depending model is called, we get the value of that model in the
same way as if we called '$c->model($name)'.  You can by the way use any type of
L<Catalys> component as a value (models, views and even controllers).

The second way is to use a coderef, which is expected to return a value suitable for
the depending model.  This gives you a little more flexibility for crafting very
custom types of dependencies.  If you use a coderef you will get three values,
the application (or context depending on if the depending model does ACCEPT_CONTEXT),
the component name and a reference to any static configuration for the model (from
the global configuration, for example).

B<NOTE>: Currently we only map dependencies 'one level' into the configuration
hash.  Which means the following works as expected:

    MyApp->map_dependencies(
      'Model::Foo' => {
        baz => sub {
          my ($app_or_ctx, $component_name, $config) = @_;
          return ...;
        },
      },
    );

But not this:

    MyApp->map_dependencies(
      'Model::Foo' => {
        baz => {
          bar => sub {
          my ($app_or_ctx, $component_name, $config) = @_;
          return ...;
          },
        },
      },
    );

I'm not sure if I consider this limitation a feature or not... If you have good
use cases let me know and I'll consider a fix.

=head1 METHODS

This plugin defines the following methods

=head2 map_dependencies

Example:

    MyApp->map_dependencies(
      'Model::AnotherModel' => { aaa => 'Model::Foo' },
      'Model::Foo' => {
        bar => 'Model::Bar',
        baz => sub {
          my ($app_or_ctx, $component_name, $config) = @_;
          return ...;
        },
      },
    );

Maps a list of components and dependencies.

=head1 map_dependency

Maps a single component to a hashref of dependencies.

=head1 CONFIGURATION

This plugin defines the configuration namespace 'Plugin::MapComponentDependencies'
and defines the following keys:

=head2 map_dependencies

A Hashref where the key is a target component and the value is a hashref of arguments
that will be sent to it during initializion.

    MyApp->config(
      'Plugin::MapComponentDependencies' => {
        map_dependencies => {
          'Model::Foo' => {
            bar => 'Model::Bar',
            baz => sub {
              my ($app_or_ctx, $component_name, $from_config_args) = @_;
              return ...;
            },
          },
        },
      },
    );

B<NOTE:> for simplicity you can place your hashref of configuration directly under the
plugin namespace.

    MyApp->config(
      'Plugin::MapComponentDependencies' => {
        'Model::Foo' => {
          bar => 'Model::Bar',
          baz => sub {
            my ($app_or_ctx, $component_name, $from_config_args) = @_;
            return ...;
          },
        },
      },
    );

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::InjectionHelpers>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
