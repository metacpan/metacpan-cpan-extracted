package Curio::Role;
our $VERSION = '0.02';

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

=head1 SUPPORT

See L<Curio/SUPPORT>.

=head1 AUTHORS

See L<Curio/AUTHORS>.

=head1 COPYRIGHT AND LICENSE

See L<Curio/COPYRIGHT AND LICENSE>.

=cut

