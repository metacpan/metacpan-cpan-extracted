package API::Docker::Role::Entity::Plugin;
# ABSTRACT: Plugin operations, on the generated plugin type
our $VERSION = '0.006';
use Moo::Role;
with 'API::Docker::Role::Entity';
requires 'name';
use API::Docker::Type::Plugin;
use Carp qw( croak );
use Package::Stash;
use namespace::clean;


sub inspect {
  my ($self) = @_;
  return $self->client->plugins->inspect($self->name);
}


sub enable {
  my ($self, %opts) = @_;
  return $self->client->plugins->enable($self->name, %opts);
}


sub disable {
  my ($self, %opts) = @_;
  return $self->client->plugins->disable($self->name, %opts);
}


sub remove {
  my ($self, %opts) = @_;
  return $self->client->plugins->remove($self->name, %opts);
}


sub configure {
  my ($self, @settings) = @_;
  return $self->client->plugins->configure($self->name, @settings);
}


sub upgrade {
  my ($self, %opts) = @_;
  return $self->client->plugins->upgrade($self->name, %opts);
}


sub push {
  my ($self, %opts) = @_;
  return $self->client->plugins->push($self->name, %opts);
}


# --- composition -----------------------------------------------------------
#
# Here rather than in API::Docker::API::Plugins, for the reason spelled out in
# API::Docker::Role::Entity::Container: loading this role is what puts the
# methods on the class.
#
# The clash check is not decoration. Moo composes a role into a class the
# class-wins way, so a generated accessor of the same name as a method here
# would silently keep its place and the method would be missing -- and the
# generated classes are written from a specification that grows fields
# without asking. This is the resource where the two vocabularies come
# closest: the class already declares `config`, `enabled` and `settings`
# beside this role's `configure` and `enable`. None of the seven names
# collides today; a future one says so on the first `use`.
{
  my @provided = Package::Stash->new(__PACKAGE__)->list_all_symbols('CODE');
  for my $class ('API::Docker::Type::Plugin') {
    my $fields = $class->docker_attributes;
    my @clash = sort grep { $fields->{$_} } @provided;
    croak __PACKAGE__ . ': ' . $class . ' declares ' . join(', ', @clash)
      . ' as a daemon field; the generated accessor would win over the '
      . 'method of that name and it would be missing without a word'
      if @clash;
    Moo::Role->apply_roles_to_package($class, __PACKAGE__);
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Role::Entity::Plugin - Plugin operations, on the generated plugin type

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my ($plugin) = @{ $docker->plugins->list };

    say $plugin->name;
    say $plugin->enabled ? 'enabled' : 'disabled';
    say join ', ', @{ $plugin->settings->env };

    $plugin->disable;
    $plugin->configure(['DEBUG=1']);
    $plugin->enable;

=head1 DESCRIPTION

The convenience methods of a Docker managed plugin. This role is composed, at
load time, into L<API::Docker::Type::Plugin>, the generated class the daemon
answers plugin requests with -- the same definition for
C<GET /plugins> and C<GET /plugins/{name}/json>, so
L<API::Docker::API::Plugins/list> and L<API::Docker::API::Plugins/inspect>
hand back one class and there is no list-versus-inspect shape to keep apart.

=head2 The entity is addressed by name, not by id

Every method here threads C<< ->name >> through to the method of the same
name on L<API::Docker::API::Plugins>, so the options, the return values and
the failure modes are that class's -- documented there, not repeated here.
The class does carry an C<< ->id >>, but the endpoints route on the name,
which is why this role C<requires 'name'>.

C<< ->name >> is the plugin as it is B<installed locally> --
C<vieux/sshfs:latest>, or whatever local name
L<API::Docker::API::Plugins/install> was given. The remote it came from is
C<< ->plugin_reference >> (C<docker.io/vieux/sshfs:latest>), which the engine
sets on the pull, upgrade and create paths only and omits entirely otherwise
rather than sending it as null -- so it reads as C<undef> for a plugin that
never came from a registry, and differs from the name outright for one
installed under a local one. That is exactly the case where L</upgrade>
needs C<remote> spelled out.

=head2 Two shapes of Env, one level apart

C<< $plugin->settings->env >> is a list of C<KEY=value> B<strings>, which is
what L</configure> takes. C<< $plugin->config->env >> is a list of
L<API::Docker::Type::PluginEnv> objects describing those same variables --
same field name, two shapes. The daemon flattens the one into the other when
the plugin is installed. L</configure> writes to the settings, never to the
config.

=head2 Not available on Podman

Managed plugins are a Docker feature: none of these endpoints exist on
Podman, so nothing in this role works against it. See
L<API::Docker::API::Plugins/"Not available on Podman">.

Why the methods are a role applied to a generated class rather than a class
of their own: L<API::Docker::Role::Entity/DESCRIPTION>.

=head2 inspect

    my $fresh = $plugin->inspect;

Get fresh plugin information. Returns another L<API::Docker::Type::Plugin> --
the same class, since the daemon describes a plugin one way.

=head2 enable

    $plugin->enable;
    $plugin->enable(timeout => 30);

Enable the plugin.

=head2 disable

    $plugin->disable(force => 1);

Disable the plugin.

=head2 remove

    $plugin->remove(force => 1);

Remove the plugin. An enabled plugin is refused without C<force>.

=head2 configure

    $plugin->configure(['DEBUG=1']);
    $plugin->configure('DEBUG=1', 'sshkey.source=/tmp');

Set the plugin's user-configurable settings. The plugin must be disabled
first. The settings are the C<KEY=value> strings of
C<< $plugin->settings->env >>, not the objects of C<< $plugin->config->env >>
-- see L</"Two shapes of Env, one level apart">.

=head2 upgrade

    my $privileges = $docker->plugins->privileges($plugin->plugin_reference);
    $plugin->upgrade(remote => $plugin->plugin_reference,
        privileges => $privileges);

Upgrade the plugin in place. C<privileges> is required, as it is on
L<API::Docker::API::Plugins/upgrade>, and C<remote> defaults to
L<API::Docker::Type::Plugin/name> -- which is not what you want for a
plugin installed under a local name, hence
C<< ->plugin_reference >>.

=head2 push

    $plugin->push(auth => { username => 'me', password => 'secret' });

Push the plugin to a registry. B<This writes to a real registry> under the
credentials given.

C<push> shadows the Perl builtin inside this package, which is why
L<namespace::clean> is loaded. Always call it as a method.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Plugins> - the operations these forward to

=item * L<API::Docker::Type::Plugin> - the fields C<list> and C<inspect>
return

=item * L<API::Docker::Role::Entity> - why the methods live in a role

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
