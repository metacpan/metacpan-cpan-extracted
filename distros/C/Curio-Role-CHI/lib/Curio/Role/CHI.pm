package Curio::Role::CHI;
our $VERSION = '0.02';

use CHI;
use Scalar::Util qw( blessed );
use Types::Standard qw( InstanceOf HashRef );

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Curio::Role';

after initialize => sub{
    my ($class) = @_;

    my $factory = $class->factory();

    $factory->does_caching( 1 );
    $factory->cache_per_process( 1 );
    $factory->resource_method_name( 'chi' );

    return;
};

has _custom_chi => (
    is       => 'ro',
    isa      => InstanceOf[ 'CHI::Driver' ] | HashRef,
    required => 1,
    init_arg => 'chi',
    clearer  => '_clear_custom_chi',
);

has chi => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build_chi {
    my ($self) = @_;

    my $chi = $self->_custom_chi();
    $self->_clear_custom_chi();
    return $chi if blessed $chi;

    return CHI->new( %$chi );
}

1;
__END__

=encoding utf8

=head1 NAME

Curio::Role::CHI - Build Curio classes around CHI.

=head1 SYNOPSIS

Create a Curio class:

    package MyApp::Service::Cache;
    
    use Curio role => '::CHI';
    use strictures 2;
    
    export_function_name 'myapp_cache';
    always_export;
    export_resource;
    
    add_key geo_ip => (
        chi => {
            driver => 'Memory',
            global => 0,
        },
    );
    
    1;

Then use your new Curio class elsewhere:

    use MyApp::Service::Cache;
    
    my $chi = myapp_cache('geo_ip');

=head1 DESCRIPTION

This role provides all the basics for building a Curio class which
wraps around L<CHI>.

=head1 REQUIRED ARGUMENTS

=head2 chi

Holds the L<CHI> object.

May be passed as either a hashref of arguments or a pre-created
object.

=head1 FEATURES

This role turns on L<Curio::Factory/does_caching> and
L<Curio::Factory/cache_per_process>, and sets
L<Curio::Factory/resource_method_name> to C<chi> (as in L</chi>).

You can of course revert these changes:

    does_caching 0;
    cache_per_process 0;
    resource_method_name undef;

=head1 SUPPORT

Please submit bugs and feature requests to the
Curio-Role-CHI GitHub issue tracker:

L<https://github.com/bluefeet/Curio-Role-CHI/issues>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/> for
encouraging their employees to contribute back to the open source
ecosystem.  Without their dedication to quality software development
this distribution would not exist.

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

