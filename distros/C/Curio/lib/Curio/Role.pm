package Curio::Role;
our $VERSION = '0.03';

=encoding utf8

=head1 NAME

Curio::Role - Role for Curio classes.

=head1 DESCRIPTION

This L<Moo::Role> provides various shortcut methods for interacting
witht the underlying L<Curio::Factory> object.

=cut

use Curio::Factory;
use Curio::Util;

use Moo::Role;
use strictures 2;
use namespace::clean;

=head1 CLASS METHODS

=head2 fetch

    my $curio = Some::Curio::Class->fetch();
    my $curio = Some::Curio::Class->fetch( $key );

This method proxies to L<Curio::Factory/fetch_curio>.

=cut

sub fetch {
    my $class = shift;
    return $class->factory->fetch_curio( @_ );
}

=head2 inject

    MyApp::Service::Cache->inject( $curio_object );
    MyApp::Service::Cache->inject( $key, $curio_object );

This method proxies to L<Curio::Factory/inject>.

=cut

sub inject {
    my $class = shift;
    return $class->factory->inject( @_ );
}

=head2 uninject

    my $curio_object = MyApp::Service::Cache->uninject();
    my $curio_object = MyApp::Service::Cache->uninject( $key );

This method proxies to L<Curio::Factory/uninject>.

=cut

sub uninject {
    my $class = shift;
    return $class->factory->uninject( @_ );
}

=head2 factory

    my $factory = MyApp::Service::Cache->factory();

Returns the class's L<Curio::Factory> object.

This method may also be called on instances of the class.

Calling this is equivalent to calling L<Curio::Factory/find_factory>.

=cut

sub factory {
    return Curio::Factory->find_factory( shift );
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

=head2 keys

    my $keys = MyApp::Service::Cache->keys();
    foreach my $key (@$keys) { ... }

This method proxies to L<Curio::Factory/keys>.

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

