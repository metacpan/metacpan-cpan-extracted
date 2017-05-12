package Class::Pluggable;

use 5.008006;
use strict;
use warnings;
use vars qw($AUTOLOAD);
use Carp;

our $VERSION = '0.022';

sub add_plugin {
	my ($self, $plugin) = @_;

	push @{$self->_get_plugins()}, $plugin;

	{
	  no strict 'refs';
	  s/^&//, *{"$_"} = \&{"${plugin}::$_"}
		foreach @{"${plugin}::EXPORT_AS_PLUGIN"};
	}
}


sub _get_plugins {
  my $self = shift;

  if (not ref $self) {
    printf "  !! ref = %s\n", $self;
    croak("Cannot handle the plugins as Class method.");
  }

  $self->{_PLUGINS} = [] if not $self->{_PLUGINS};
  return $self->{_PLUGINS};
}


sub get_plugins {
  return @{$_[0]->_get_plugins()};
}


sub add_hook {
  my ($self, $hook, $method) = @_;

  if (defined ${$self->{_HOOK}}{$hook}) {
	carp("The hook ($hook) already in used. It will overwrite with new method.");
  }

  ${$self->{_HOOK}}{$hook} = $method;
}


sub run_hook {
  my ($self, $hook) = @_;
  my $method = ${$self->{_HOOK}}{$hook};

  if (not defined $method) {
	my $caller = caller(0);
	croak("The hook ($hook) $caller called doesn't exists.");
  }

  $self->execute_all_plugins_method($method);
}



sub remove_hook {
  my ($self, $hook) = @_;
  delete ${$self->{_HOOK}}{$hook};
}


sub execute_plugin_method {
	my ($self, $plugin, $method, @args) = @_;
	my $result;

	if (defined &{"${plugin}::$method"}) {
	  # Give $self to make the plugin method looks like object method.
	  {
		no strict 'refs';
		$result = &{"${plugin}::$method"}($self, @args);
	  }
	}
	return $result;
}

sub execute_all_plugins_method {
  my ($self, $method, @args) = @_;

  $self->execute_plugin_method($_, $method, @args)
	foreach $self->get_plugins();
}



## Deprecated Methods.
sub addPlugin { carp("deprecated method."); (shift)->add_plugin(@_) }
sub _getPlugins { carp("deprecated method."); (shift)->_get_plugins(@_) }
sub getPlugins { carp("deprecated method."); (shift)->get_plugins(@_) }
sub addHook { carp("deprecated method."); (shift)->add_hook(@_) }
sub runHook { carp("deprecated method."); (shift)->run_hook(@_) }
sub removeHook { carp("deprecated method."); (shift)->remove_hook(@_) }
sub executePluginMethod { carp("deprecated method."); (shift)->execute_plugin_method(@_) }
sub executeAllPluginsMethod { carp("deprecated method."); (shift)->execute_all_plugins_method(@_) }

1;
__END__

=head1 NAME

Class::Pluggable - Simple pluggable class.

=head1 SYNOPSIS

  use Class::Pluggable;
  use base qw(Class::Pluggable);

  # Some::Plugin::Module has sub routin called newAction
  add_plugin("Some::Plugin::Module"); 

  newAction();  # Plugged action.

=head1 DESCRIPTION

This class makes your class (sub class of Class::Pluggable) pluggable.
In this documentatin, the word "pluggable" has two meanings.

One is just simply adding new method to your pluggable classs from 
other plugin modules. So, after you plugged some modules to your class,
you can use there method exactly same as your own object method.

You can see this kind of plugin mechanism in CGI::Application and
CGI::Application::Plugin::Session.

There are one thing that Plugin developer have to know. The plugin
module MUST have @EXPORT_AS_PLUGIN to use this pluggable mechanism.
This works almost same as @EXPORT. But the methods in the
@EXPORT_AS_PLUGIN wouldn't be exported to your package. But it would
be exported to the subclass of Class::Pluggable (only when you call add_plugin()).

And the another meaning of "pluggable" is so called hook-mechanism.
For example, if you want to allow to other modules to do something
before and/or after some action. You can do like this:

  $self->execute_plugin_method($_, "before_action")
    foreach $self->get_plugins();

  ## do some your own action here.

  $self->execute_plugin_method($_, "after_action")
    foreach $self->get_plugins();

=head1 METHODS

Here are all methods of Class::Pluggable.

=over 4

=item add_plugin

  $object->add_plugin($pluginName)

This will add new plugin to your class. What you added to here
would be returned by get_plugins() method.

=item get_plugins

  @plugins = $object->get_plugins();

It will return all of plugin names that are already added to YouClass.

=item execute_plugin_method

  $result = $object->execute_plugin_method("SomePlugin", "someMethod");

This will execute the method someMethod of SomePlugin.

=item execute_all_plugin_method

  $object->execute_all_plugin_method("someMethod");

This will execute the method someMethod of all plugin we have.
This is almost same as following code.

  $self->execute_plugin_method($_, "someMethod")
    foreach $self->get_plugins();

The difference is executeAllPluginMethod can't return any values.
But executePluginMethod can.

=item add_hook

  $object->add_hook("pre-init", "pre_init");

This will add new hook to your class. Whenever run_hook("pre-init") has called,
the method pre_init of all plugins which we have will be executed.

=item run_hook

  $object->run_hook("pre-init");

This will execute the hook-method of all plugins which we have.

=item remove_hook

  $object->remove_hook("pre-init");

This will delete the hook from YourClass. After calling this method,
you cannot call run_hook("pre-init"). If you do, it will die immediately.

=head1 SEE ALSO

...

=head1 AUTHOR


Ken Takeshige, E<lt>ken.takeshige@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ken Takeshige

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
