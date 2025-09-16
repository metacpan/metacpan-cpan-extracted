# ABSTRACT: Config reader role for Dancer2 core objects
package Dancer2::Core::Role::ConfigReader;
$Dancer2::Core::Role::ConfigReader::VERSION = '2.0.0';
use Moo::Role;

use File::Spec;
use Config::Any;
use Hash::Merge::Simple;
use Carp 'croak';
use Module::Runtime 'require_module';

use Dancer2::Core::Factory;
use Dancer2::Core;
use Dancer2::Core::Types;
use Dancer2::FileUtils 'path';

has config_location => (
    is      => 'ro',
    isa     => ReadableFilePath,
    lazy    => 1,
    default => sub { $ENV{DANCER_CONFDIR} || $_[0]->location },
);

# The type for this attribute is Str because we don't require
# an existing directory with configuration files for the
# environments.  An application without environments is still
# valid and works.
has environments_location => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        $ENV{DANCER_ENVDIR}
          || File::Spec->catdir( $_[0]->config_location, 'environments' )
          || File::Spec->catdir( $_[0]->location,        'environments' );
    },
);

# It is required to get environment from the caller.
# Environment should be passed down from Dancer2::Core::App.
has environment => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

# It is required to get location from the caller.
has location => (
    is       => 'ro',
    isa      => ReadableFilePath,
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Core::Role::ConfigReader - Config reader role for Dancer2 core objects

=head1 VERSION

version 2.0.0

=head1 DESCRIPTION

This role is implemented by different
config readers. A config reader creates the
configuration for Dancer2 app.
Config can be created by reading configuration
files, from environment variables, by fetching
it from a cloud service, or any other means.

Default config reader is C<Dancer2::ConfigReader::Config::Any>
but user can create his own config reader
if he wants to replace or augment
the default method of config creation.
That method should implement this role.

The implementing module gets the following parameters
during creation:

=head1 ATTRIBUTES

=head2 environment

The name of the environment used, e.g.
production, development, staging.

=head2 location

The absolute path to the directory where the server started.

=head2 default_config

A hash ref which contains the default values.

These arguments are passed when the object is created by
C<Dancer2::Core::App>.
ConfigReader then passes C<environment> and C<location> forward to every
config reader class when it instantiates them.
How the config reader applies them, depend on its needs.

Provides a C<config> attribute that - when accessing
the first time - feeds itself by finding and parsing
configuration files.

Also provides a C<setting()> method which is
supposed to be used by externals to
read/write config entries.

=head2 location

Absolute path to the directory where the server started.

=head2 config_location

Gets the location from the configuration. Same as C<< $object->location >>.

=head2 environments_location

Gets the directory where the environment files are stored.

=head2 config

Returns the whole configuration.

=head2 environments

Returns the name of the environment.

=head1 METHODS

=head2 read_config

Load the configuration.
Whatever source the config comes from, files, env vars, etc.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
