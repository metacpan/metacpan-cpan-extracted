package Data::Shared::Adapter::Map;
use strict;
use warnings;
use Carp ();
use parent 'Data::Shared::Adapter::Keyed';

our $VERSION = '0.01';

our @CARP_NOT = qw(Data::Shared);

sub perform_push { Carp::croak("Data::Shared: push is not supported for map mounts (use shared_set/shared_call)") }
sub perform_pop  { Carp::croak("Data::Shared: pop is not supported for map mounts (use shared_get/shared_call)") }

1;

__END__

=head1 NAME

Data::Shared::Adapter::Map - Internal adapter for map-like mounts (Data::Shared)

=head1 DESCRIPTION

Internal to L<Data::Shared>; not a public API. Translates generic
verbs for single-key mounts (HashMap, Buffer, RadixTree, Intern,
Pool, PerfectHash) into native method calls through
L<Data::Shared::Adapter::Keyed>, which calls that component a key.

=cut
