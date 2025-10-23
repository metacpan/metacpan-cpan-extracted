# ABSTRACT: Role that represents the config of Dancer2 App
package Dancer2::Core::Role::HasConfig;
$Dancer2::Core::Role::HasConfig::VERSION = '2.0.1';
use Moo::Role;

use File::Spec;
use Config::Any;
use Hash::Merge::Simple;
use Carp 'croak';
use Module::Runtime qw{ require_module use_module };

use Dancer2::Core::Factory;
use Dancer2::Core;
use Dancer2::Core::Types;
use Dancer2::FileUtils 'path';
use Dancer2::ConfigUtils 'normalize_config_entry';

has config => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 0,
    builder => '_build_config',
);

has local_triggers => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

has global_triggers => (
    is      => 'ro',
    isa     => HashRef,
    default => sub {
        my $triggers = {
            traces => sub {
                my ( $self, $traces ) = @_;
                # Carp is already a dependency
                $Carp::Verbose = $traces ? 1 : 0;
            },
        };

        my $runner_config;
        {
            no warnings 'once';
            $runner_config = defined $Dancer2::runner
                           ? Dancer2->runner->config
                           : {};
        }

        for my $global ( keys %$runner_config ) {
            next if exists $triggers->{$global};
            $triggers->{$global} = sub {
                my ($self, $value) = @_;
                Dancer2->runner->config->{$global} = $value;
            }
        }

        return $triggers;
    },
);

sub _set_config_entries {
    my ( $self, @args ) = @_;
    my $no = scalar @args;
    while (@args) {
        $self->_set_config_entry( shift(@args), shift(@args) );
    }
    return $no;
}

sub _set_config_entry {
    my ( $self, $name, $value ) = @_;

    $value = normalize_config_entry( $name, $value );
    $value = $self->_compile_config_entry( $name, $value, $self->config );
    $self->config->{$name} = $value;
}

sub settings { shift->config }

sub setting {
    my $self = shift;
    my @args = @_;

    return ( scalar @args == 1 )
      ? $self->settings->{ $args[0] }
      : $self->_set_config_entries(@args);
}

sub has_setting {
    my ( $self, $name ) = @_;
    return exists $self->config->{$name};
}

# private

sub _compile_config_entry {
    my ( $self, $name, $value, $config ) = @_;

    my $trigger = exists $self->local_triggers->{$name} ?
                         $self->local_triggers->{$name} :
                         $self->global_triggers->{$name};

    defined $trigger or return $value;

    return $trigger->( $self, $value, $config );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Core::Role::HasConfig - Role that represents the config of Dancer2 App

=head1 VERSION

version 2.0.1

=head1 DESCRIPTION

This role provides a C<config> attribute that is
used to read the configuration.
When accessing
the first time, it calls method C<_build_config()> which
must be implemented by the using class.
This method should return the whole config which has been
created by executing one or more
B<ConfigReader> packages.

Also provides a C<setting()> method which is supposed to be used by externals to
read/write config entries.

=head1 ATTRIBUTES

=head2 config

Returns the whole configuration.

=head1 METHODS

=head2 settings

Alias for config. Equivalent to <<$object->config>>.

=head2 setting

Get or set an element from the configuration.

=head2 has_setting

Verifies that a key exists in the configuration.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
