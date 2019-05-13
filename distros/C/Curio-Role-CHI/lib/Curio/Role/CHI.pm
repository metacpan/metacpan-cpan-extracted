package Curio::Role::CHI;
our $VERSION = '0.01';

use CHI;
use Types::Standard qw( InstanceOf );

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Curio::Role';
with 'MooX::BuildArgs';

after initialize => sub{
    my ($class) = @_;

    my $factory = $class->factory();

    $factory->does_caching( 1 );
    $factory->cache_per_process( 1 );

    return;
};

has chi => (
    is  => 'lazy',
    isa => InstanceOf[ 'CHI::Driver' ],
);

sub _build_chi {
    my ($self) = @_;

    my $chi = CHI->new(
        %{ $self->build_args() },
    );

    $self->clear_build_args();

    return $chi;
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
    
    use Exporter qw( import );
    our @EXPORT = qw( myapp_cache );
    
    add_key geo_ip => (
        driver => 'Memory',
        global => 0,
    );
    
    sub myapp_cache {
        return __PACKAGE__->fetch( @_ )->chi();
    }
    
    1;

Then use your new Curio class elsewhere:

    use MyApp::Service::Cache;
    
    my $chi = myapp_cache('geo_ip');

=head1 DESCRIPTION

This role provides all the basics for building a Curio class
which wraps around L<CHI>.

Fun fact, this L</SYNOPSIS> is functionally identical to
L<Curio/SYNOPSIS>.

=head1 ATTRIBUTES

=head2 chi

    my $chi = MyApp::Service::Cache->fetch('geo_ip)->chi();

Holds the L<CHI> object.

=head1 CACHING

This role sets the L<Curio::Factory/does_caching> and
L<Curio::Factory/cache_per_process> features.

C<cache_per_process> is important to set since there are
quite a few CHI drivers which do not like to be re-used
across processes.

You can of course disable these features.

    does_caching 0;
    cache_per_process 0;

=head1 NO KEYS

If you'd like to create a CHI Curio class which exposes a
single CHI object and does not support keys then here's a
slightly altered version of the L</SYNOPSIS> to get you
started.

Create a Curio class:

    package MyApp::Service::GeoIPCache;
    
    use Curio role => '::CHI';
    
    use Exporter qw( import );
    our @EXPORT = qw( myapp_geo_ip_cache );
    
    default_arguments (
        driver => 'Memory',
        global => 0,
    );
    
    sub myapp_geo_ip_cache {
        return __PACKAGE__->fetch( @_ )->chi();
    }
    
    1;

Then use your new Curio class elsewhere:

    use MyApp::Service::GeoIPCache;
    
    my $chi = myapp_geo_ip_cache();

=head1 SUPPORT

Please submit bugs and feature requests to the
Curio-Role-CHI GitHub issue tracker:

L<https://github.com/bluefeet/Curio-Role-CHI/issues>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 AUTHORS

    Aran Clary Deltac <aran@bluefeet.dev>

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

