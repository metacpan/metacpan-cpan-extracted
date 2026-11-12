package Data::Shared::Adapter::Set;
use strict;
use warnings;
use Carp ();
use parent 'Data::Shared::Adapter::Keyed';

our $VERSION = '0.01';

our @CARP_NOT = qw(Data::Shared);

sub _noun { 'member' }

sub perform_push { Carp::croak("Data::Shared: push is not supported for set mounts (use shared_set/shared_call)") }
sub perform_pop  { Carp::croak("Data::Shared: pop is not supported for set mounts (use shared_call)") }

1;

__END__

=head1 NAME

Data::Shared::Adapter::Set - Internal adapter for set-like mounts (Data::Shared)

=head1 DESCRIPTION

Internal to L<Data::Shared>; not a public API. Translates generic
verbs for single-member mounts (Bloom filters, BitSet, RoaringBitmap,
SortedSet, DisjointSet) into native method calls through
L<Data::Shared::Adapter::Keyed>, which calls that component a member.

=cut
