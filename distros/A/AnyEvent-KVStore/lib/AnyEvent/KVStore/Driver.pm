=head1 NAME

   AnyEvent::KVStore::Driver -- The Driver role for AnyEvent::KVStore

=head1 VERSION

   0.1.2

=cut

package AnyEvent::KVStore::Driver;
our $VERSION = '0.1.1';
use strict;
use warnings;
use Moo::Role;
requires qw(read exists list write watch);

=head1 SYNOPSIS

    package AnyEvent::KVStore::Test;

    use strict;
    use warnings;
    use Moose; # or Moo
    with 'AnyEvent::KVStore::Driver';

    # implement read, exists, list, write, and watch.
    
    # Then, elsewhere:

    my $kvstore = AnyEvent::KVStore->new('test', {});
    ...

=head1 DESCRIPTION

This module defines and provides the interface guarantees for the drivers for
the L<AnyEvent::KVStore> framework. If you are writing a driver you will want
to review this section carefully.

=head2 Lifecycle

Drivers are instantiated with the C<new()> function and persist until garbage
collection removes them.  Usually connection will be lazily created based on
the configuration hash provided since Moo usually creates the constructor for
us.

=head2 Required Methods

=over

=item $string = $store->read($key) (prototype $$)

This method MUST read and return the value stored by key C<$key>

=item $bool = $store->exists($key) (prototype $$)

This method MUST check to see if the key exists and return TRUE if so, FALSE
otherwise.

=item @strings = $store->list($prefix) (prototype $$)

This method MUST take in a string, and return a list of strings of all keys
in the store beginning with C<$prefix>.

=item $success = $store->write($key, $value) (prototype $$$)

This method MUST take two strings, and write the second to the key/value store
with the first argument being the key, and the second being the value.

If the value is C<undef> the key must be deleted.

=item void $store->watch($prefix, $callback) (prototype ($&)

=back

Methods SHOULD use Perl prototypes, particularly for Watch so that blocks can
be passed in as well as coderefs.

=head1 OTHER INFO

For copyright, licensing and copying, bog tracker and other items, see the POD
for the C<AnyEvent::KVStore> module.

=cut

1;
