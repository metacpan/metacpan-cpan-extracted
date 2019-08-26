package Catalyst::Model::Curio;
our $VERSION = '0.03';

=encoding utf8

=head1 NAME

Catalyst::Model::Curio - Curio Model for Catalyst.

=head1 SYNOPSIS

Create your model class:

    package MyApp::Model::Cache;
    
    use Moo;
    use strictures 2;
    use namespace::clean;
    
    extends 'Catalyst::Model::Curio';
    
    __PACKAGE__->config(
        class  => 'MyApp::Service::Cache',
    );
    
    1;

Then use it in your controllers:

    my $chi = $c->model('Cache::geo_ip');

=head1 DESCRIPTION

This module glues L<Curio> classes into Catalyst's model system.

This distribution also comes with L<Catalyst::Helper::Model::Curio>
which makes it somewhat simpler to create your Catalyst model class.

You may want to check out L<Curio/Use Curio Directly> for an
alternative viewpoint on using Catalyst models when you are
already using Curio.

=cut

use Curio qw();
use Module::Runtime qw( require_module );
use Types::Common::String qw( NonEmptySimpleStr );
use Types::Standard qw( Bool );

use Moo;
use strictures 2;
use namespace::clean;

extends 'Catalyst::Model';

our $_KEY;

my %installed_key_model_classes;

sub BUILD {
    my ($self) = @_;

    # Get the Curio class loaded early.
    require_module( $self->class() );

    $self->_install_key_models();

    return;
}

sub ACCEPT_CONTEXT {
    my ($self) = @_;

    my $method = $self->method();

    my $key = $self->key() || $_KEY;

    return $self->class->$method(
        $key ? $key : (),
    );
}

sub _install_key_models {
    my ($self) = @_;

    return if $self->key();

    my $model_class = ref( $self );
    return if $installed_key_model_classes{ $model_class };

    my $model_name = $model_class;
    $model_name =~ s{^.*::(?:Model|M)::}{};

    foreach my $key (@{ $self->class->declared_keys() }) {
        no strict 'refs';

        *{"$model_class\::$key\::ACCEPT_CONTEXT"} = sub{
            my ($self, $c) = @_;
            local $_KEY = $key;
            return $c->model( $model_name );
        };
    }

    $installed_key_model_classes{ $model_class } = 1;

    return;
}

=head1 CONFIG ARGUMENTS

=head2 class

    class => 'MyApp::Service::Cache',

The Curio class that this model wraps around.

This is required to be set, otherwise Catalyst will throw
and exception when trying to load your model.

=cut

has class => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    required => 1,
);

=head2 key

    key => 'geo_ip',

If your Curio class supports keys then, if set, this forces
your model to interact with one key only.

=cut

has key => (
    is  => 'ro',
    isa => NonEmptySimpleStr,
);

=head2 method

    method => 'connect',

By default Catalyst's C<model()> will call the C<fetch()>
method on your L</class> which will return a Curio object.
If you'd like, you can change this to call a different
method, returning something else of your choice.

You could, for example, have a method in your Curio class
which returns the the resource that your Curio object makes:

    sub connect {
        my $class = shift;
        return $class->fetch( @_ )->chi();
    }

Then set the C<method> to C<connect> causing C<model()> to
return the CHI object instead of the Curio object.

=cut

has method => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => 'fetch',
);

1;
__END__

=head1 HANDLING KEYS

=head2 No Keys

A Curio class which does not support keys just means you don't
set the L</key> config argument.

=head2 Single Key

If your Curio class does support keys you can choose to create a model
for each key you want exposed in catalyst by specifying the L</key>
config argument in each model for each key you want available in Catalyst.
Each model would have the same L</class>.

=head2 Multiple Keys

If your Curio class supports keys and you do not set the L</key>
config argument then the model will automatically create pseudo
models for each key.

This is done by appending each declared key to your model name.
You can see this in the L</SYNOPSIS> where the model name is
C<Cache> but since L</key> is not set, and the Curio class does
have declared keys then the way you get the model is by appending
C<::geo_ip> to the model name, or whatever key you want to access.

=head1 SUPPORT

Please submit bugs and feature requests to the
Catalyst-Model-Curio GitHub issue tracker:

L<https://github.com/bluefeet/Catalyst-Model-Curio/issues>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut

