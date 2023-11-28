=head1 NAME

   AnyEvent::KVStore::Hash -- A simple, hash-based Key/value store

=cut

package AnyEvent::KVStore::Hash;
use 5.010;
use strict;
use warnings;
no autovivification;
use Moo;
use Types::Standard qw(HashRef);
with 'AnyEvent::KVStore::Driver';

=head1 VERSION

  0.1.2

=cut

our $VERSION = '0.1.2';

=head1 SYNOPSIS

   use AnyEvent::KVStore;
   my $store = AnyEvent::KVStore->new(module => 'hash', config => {});
   $store->write('foo', 'bar');
   $store->watch('f', sub { my ($k, $v) = @_; warn "Setting $k to $v"; });
   $store->write('far', 'over there');

=head2 DESCRIPTION

L<AnyEvent::KVStore> ships with a very simple, non-blocking key-value store for
testing, proofs of concepts, and other purposes.  This has all the advantages
and disadvantages of just storing the data in a hash table, but comes with
callback features on write.  You can use this as a glorified enriched hashtable
or you can use other modules in this framework to connect to shared key/value
stores.

Each kvstore here has its own keyspace and watch list.

=head2 Watch Behavior

C<AnyEvent::KVStore::Hash> allows for unlimited watches to be set up, and
because this key/value store is private, the callbacks are handled synchronous
to the writes.  If you want asynchronous callbacks, you can use the
C<unblock_sub> function from L<Coro>.

Watches are currently indexed by the first letter of the prefix, or if no
prefix is given, an empty string.  Watches are then checked (and executed)
in order of:

=over

=item First empty prefix watches

These are run (there is no checking) in order of creation

=item Then the first letter of the key is used to match prefixes.

The prefixes are checked and run un order of creation here too.  This may, in
the future, change to be more alphabetically ordered.

=back

This behavior is subect to change.

=cut

has _store    => (is => 'ro', isa => HashRef, default => sub { {} });

has _watches  => (is => 'ro', isa => HashRef, default => sub { {} });

=head1 METHODS

Unless otherwise noted, these do exactly what the documentation in 
C<AnyEvent::KVStore> and C<AnyEvent::KVStore::Driver> suggest.

=head2 read

=head2 exists

=head2 list

=head2 write

=head2 watch

In this module, watches are run synchronously, not via AnyEvent's event loop.

If you wish to use AnyEvent's event loop, use condition variables with
callbacks set and C<send> them.

=cut

sub read($$) {
    my ($self, $key) = @_;
    return $self->_store->{$key};
}

sub exists($$) {
    my ($self, $key) = @_;
    my $href = $self->_store;
    return exists $href->{$key};
}

sub list($$) {
    my ($self, $prefix) = @_;
    return grep { $_ =~ /^$prefix/ } keys %{$self->_store}
        if defined $prefix and $prefix ne '';
    return keys %{$self->_store};
}

sub write($$$) {
    my ($self, $key, $value) = @_;
    # check watches
    if (exists $self->_watches->{''}){
        for my $w (@{$self->_watches->{''}}){
            $w->{cb}($key, $value);
        }
    }
    my $first_letter = substr($key, 0, 1);
    if (exists $self->_watches->{$first_letter}){
        for my $w (@{$self->_watches->{$first_letter}}){
            $w->{cb}($key, $value) if $key =~ /^$w->{pfx}/;
        }
    }
    if (not defined $value) {
        delete $self->_store->{$key};
        return 1;
    }
    $self->_store->{$key} = $value;
    return 1;
}

sub watch($$&) {
    my ($self, $pfx, $cb) = @_;
    my $first;
    if ($pfx eq '' or not defined $pfx){
       $first = '';
    } else {
       $first = substr($pfx, 0, 1);
    }
    $self->_watches->{$first} //= [];
    push @{$self->_watches->{$first}}, {pfx => $pfx, cb => $cb};
    return 1;
}

=head1 MORE INFORMATION

For information on Copyright, Licensing, Contributing, Bug trackers, etc. see
the documentation of C<AnyEvent::KVStore>, which this module is distributed as
a part of.

=cut

1;
