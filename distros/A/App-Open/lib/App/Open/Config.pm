#===============================================================================
#
#         FILE:  Config.pm
#
#  DESCRIPTION:  App:;Open::Config - basic configuration interface to App::Open
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  06/02/2008 02:27:27 AM PDT
#     REVISION:  ---
#===============================================================================

package App::Open::Config;

=head2 METHODS

=over 4

=cut

use strict;
use warnings;

use YAML::Syck;
$YAML::Syck::ImplicitTyping = 1;

=item new($config_file)

Constructor, optionally takes the name of a config file; calls load_config()
automatically.

=cut

sub new {
    my ( $class, $config_file ) = @_;

    my $self = bless { config_file => ( $config_file || "" ) }, $class;

    $self->load_config;

    return $self;
}

=item load_config()

Loads the configuration (or resets it). If there is trouble reading the
configuration, it will supply a default empty configuration.

This call will die if the configuration is available, not undefined and does
not evaluate to a hash.

=cut

sub load_config {
    my $self = shift;

    my $config;

    eval { $config = YAML::Syck::LoadFile( $self->{config_file} ) };

    # load a default configuration if Syck fails us
    $self->{config} = $@ ? {} : ( $config || {} );

    if ( !ref( $self->{config} ) || ref( $self->{config} ) ne 'HASH' ) {
        die "INVALID_CONFIGURATION";
    }

    return;
}

=item load_backends(@backends)

A frontend to load_backend(). Takes a list of backends to be processed in priority.

=cut

sub load_backends {
    my ( $self, @backends ) = @_;

    #
    # This is a lot more complex than I'd like, but it keeps the end-user
    # configuration tolerable.
    #
    # Basically, if the backend value is a hash, it passes the key to
    # load_backend() which will ferret the arguments out. The upside of this is
    # that it's trivial to configure one backend, but multiple backends cannot
    # guarantee ordering. The value associated with this key must be an array,
    # and will be used as the arguments for the backend.
    #
    # If the value is an array, it expects each array element to be a hash,
    # with the keys `name` and `args`, which represent the backend name and
    # arguments respectively. The `args` must be an array. The whole top-level
    # hash for the backend (the array element) is passed to load_backend().
    #

    if ( exists( $self->config->{backend} )
        and defined( $self->config->{backend} ) )
    {
        if (ref( $self->config->{backend} )) {
            if (ref($self->config->{backend}) eq 'HASH') {
                foreach my $backend ( keys %{ $self->config->{backend} } ) {
                    $self->load_backend($backend);
                }
            } elsif (ref($self->config->{backend}) eq 'ARRAY') {
                foreach my $backend (@{$self->config->{backend}}) {
                    if (ref($backend) eq 'HASH') {
                        $self->load_backend($backend);
                    }
                }
            }
        }
        else {
            $self->load_backend( $self->config->{backend} );
        }
    }

    if (@backends) {
        foreach my $backend (@backends) {
            $self->load_backend($backend);
        }
    }

    return;
}

=item load_backend($backend)

Gets the parameters for the backend, name and arguments. Requires the module
for the backend via require_backend() and on success, constructs an object from
that module with the supplied arguments and stores it in the backend list.

The $backend argument can either be a hashref or string, this is detailed in
some comments in load_backends().

If the backend supplied cannot be loaded, it will die with NO_BACKEND_FOUND.

=cut

sub load_backend {
    my ( $self, $backend ) = @_;

    if (ref($backend) eq 'HASH') {
        if ($backend->{name}) {
            my $module = $self->require_backend($backend->{name});
            if ($module) {
                my $obj = $module->new($backend->{args});
                push @{ $self->backend_order }, $obj;
                return $module;
            }
        }
    } elsif (!ref($backend)) {
        my $module = $self->require_backend($backend);
        if ($module) {
            my $obj = $module->new( $self->config->{backend}{$backend} );
            push @{ $self->backend_order }, $obj;
            return $module;
        }
    }

    die "NO_BACKEND_FOUND $backend";
}

=item require_backend($backend)

Attempts to use the module that corresponds to the backend name. This will try
a couple of namespaces to load a backend:

=over 4

=item App::Open::Backend::

=item "" (root namespace)

=back

On success, it will return the module name used. Otherwise, undef.

=cut

sub require_backend {
    my ($self, $backend) = @_;

    foreach my $backend_try ( "App::Open::Backend::", "" ) {
        my $module = "$backend_try$backend";

        eval "use $module";

        unless ($@) {
            return $module;
        }
    }

    return undef;
}

=item config()

Convenience call to access the config hash.

=cut

sub config { $_[0]->{config} }

=item config_file()

Convenience call to access the config filename.

=cut

sub config_file { $_[0]->{config_file} }

=item backend_order()

Returns the lookup order of the various MIME backends as arrayref.

In the instance that this does not already exist when it is called, a new,
empty arrayref will be created and returned.

=cut

sub backend_order {
    my $self = shift;

    return $self->{backend_order} if ( $self->{backend_order} );

    return $self->{backend_order} = [];
}

=back

=cut

1;
