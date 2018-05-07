package Class::Method::Cache::FastMmap;

# ABSTRACT: Cache method results using Cache::FastMmap

use v5.10.1;

use strict;
use warnings;

use Cache::FastMmap;
use Class::Method::Modifiers qw/ install_modifier /;
use Exporter qw/ import /;
use Object::Signature ();

our $VERSION = 'v0.1.1';

our @EXPORT    = qw/ cache /;
our @EXPORT_OK = @EXPORT;


sub cache {
    my ( $method, %options ) = @_;

    my $target = caller;

    my $key_cb = delete $options{key_cb} // \&Object::Signature::signature;

    install_modifier $target, 'around', $method, sub {
        my $next = shift;
        my $self = shift;

        state $cache = Cache::FastMmap->new(%options);

        my $key = $key_cb->( [ $self, @_ ] );
        my $value = $cache->get($key);
        unless ( defined $value ) {
            $cache->set( $key, $value = $self->$next(@_) );
        }
        return $value;
    };

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Method::Cache::FastMmap - Cache method results using Cache::FastMmap

=head1 VERSION

version v0.1.1

=head1 SYNOPSIS

  package MyClass;

  use Class::Method::Cache::FastMmap;

  sub my_method {
    ...
  }

  cache 'my_method' => (
     serializer  => 'storable',
     expire_time => '1h',
  );

=head1 DESCRIPTION

This package allows you to easily cache the results of a method call
using L<Cache::FastMmap>.

=head1 EXPORTS

=head2 C<cache>

  cache $method => %options;

This wraps the C<$method> with a function that caches the return value.

It assumes that the method returns a defined scalar value and that the
method arguments are serialisable.

The C<%options> are used to configure L<Cache::FastMmap>.

A special option called C<key_cb> is used to provide a custom
key-generation function.  If none is specified, then
L<Object::Signature> is used.

The function should expect a single argument with an array reference
corresponding to the original method call parameters:

  $key_cb->( [ $self, @_ ] );

=head1 SEE ALSO

L<Cache::FastMmap>

L<Object::Signature>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Class-Method-Cache-FastMmap>
and may be cloned from L<git://github.com/robrwo/Class-Method-Cache-FastMmap.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Class-Method-Cache-FastMmap/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
