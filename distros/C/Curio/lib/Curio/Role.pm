package Curio::Role;
our $VERSION = '0.04';

=encoding utf8

=head1 NAME

Curio::Role - Role for Curio classes.

=head1 DESCRIPTION

This L<Moo::Role> provides various shortcut methods for interacting
witht the underlying L<Curio::Factory> object.

=cut

use Curio::Factory;
use Curio::Util;
use Package::Stash;

use Moo::Role;
use strictures 2;
use namespace::clean;

my %is_exporter_setup;

sub import {
    my ($class) = @_;

    my $factory = $class->factory();
    my $name = $factory->export_function_name();
    return if !defined $name;

    if (!$is_exporter_setup{ $class }) {
        my $stash = Package::Stash->new( $class );

        $stash->add_symbol(
            "&$name",
            $factory->export_resource()
                ? subname( $name, _build_export_resource( $factory ) )
                : subname( $name, _build_export_curio( $factory ) ),
        ) if !$class->can($name);

        $stash->add_symbol(
            $factory->always_export() ? '@EXPORT' : '@EXPORT_OK',
            [ $name ],
        );

        $is_exporter_setup{ $class } = 1;
    }

    goto &Exporter::import;
}

sub _build_export_curio {
    my $factory = shift;
    return sub{ $factory->fetch_curio( @_ ) };
}

sub _build_export_resource {
    my $factory = shift;
    return sub{ $factory->fetch_resource( @_ ) };
}

=head1 CLASS METHODS

=head2 fetch

    my $curio = Some::Curio::Class->fetch();
    my $curio = Some::Curio::Class->fetch( $key );

This proxies to L<Curio::Factory/fetch_curio>.

=cut

# The real fetch method is installed in the curio class by:
# Curio::Factory::_install_fetch_method()
sub fetch { undef }

=head2 find_curio

    my $curio_object = MyApp::Service::Cache->find_curio( $resource );

This proxies to L<Curio::Factory/find_curio>.

=cut

sub find_curio {
    my $class = shift;
    return $class->factory->find_curio();
}

=head2 inject

    MyApp::Service::Cache->inject( $curio_object );
    MyApp::Service::Cache->inject( $key, $curio_object );

This proxies to L<Curio::Factory/inject>.

=cut

sub inject {
    my $class = shift;
    return $class->factory->inject( @_ );
}

=head2 inject_with_guard

    my $guard = MyApp::Service::Cache->inject_with_guard(
        $curio_object,
    );
    
    my $guard = MyApp::Service::Cache->inject_with_guard(
        $key, $curio_object,
    );

This proxies to L<Curio::Factory/inject_with_guard>.

=cut

sub inject_with_guard {
    my $class = shift;
    return $class->factory->inject_with_guard( @_ );
}

=head2 uninject

    my $curio_object = MyApp::Service::Cache->uninject();
    my $curio_object = MyApp::Service::Cache->uninject( $key );

This proxies to L<Curio::Factory/uninject>.

=cut

sub uninject {
    my $class = shift;
    return $class->factory->uninject( @_ );
}

=head2 initialize

Sets up your class's L<Curio::Factory> object and is automatically
called when you C<use Curio;>.  This is generally not called
directly by end-user code.

=cut

sub initialize {
    Curio::Factory->new( class => shift );
    return;
}

=head1 CLASS ATTRIBUTES

=head2 factory

    my $factory = MyApp::Service::Cache->factory();

Returns the class's L<Curio::Factory> object.

Calling this is equivalent to calling L<Curio::Factory/find_factory>,
but is much faster.

=cut

# The real factory attribute is installed in the curio class by:
# Curio::Factory::_install_factory_method()
sub factory { undef }

=head2 keys

    my $keys = MyApp::Service::Cache->keys();
    foreach my $key (@$keys) { ... }

This proxies to L<Curio::Factory/keys>.

=cut

sub keys {
    my $class = shift;
    return $class->factory->keys( @_ );
}

1;
__END__

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

