package Algorithm::ConsistentHash::CHash;
use strict;
use warnings;
use XSLoader;

our $VERSION = '0.04';

XSLoader::load('Algorithm::ConsistentHash::CHash', $VERSION);

1;

__END__

=head1 NAME

Algorithm::ConsistentHash::CHash - XS bindings to bundled Consistent Hash library

=head1 SYNOPSIS

    my $ch = Algorithm::ConsistentHash::CHash->new(
        ids      => [ 'server1', 'server2' ],
        replicas => 100,
    );

    my $node = $ch->lookup('foo');
    # $node is either server1 or server2, consistently

=head1 DESCRIPTION

Consistent Hashing allows to spread data out across multiple IDs, ensuring
relatively-even distribution using replicas. The more replicas, the better
distribution (but lower performance).

Given a consistent hash, adding a node to the hash only requires reassigning
a minimal number of keys.

A C implementation of the Consistent Hash algorithm is bundled in this package,
along with the XS bindings to it. This might change in the future.

=head1 METHODS

=head2 new

    my $ch = Algorithm::ConsistentHash::CHash->new(
        ids      => [ @nodes_names ],
        replicas => $number_of_replicas,
    );

Create a new L<Algorithm::ConsistentHash::CHash> object. This internally
generates a new hash.

=head2 lookup

    my $node_name = $ch->lookup($key);

Looks up a node in the hash by the given key.

=head1 SEE ALSO

L<https://github.com/dgryski/libchash> - The bundled C library.

L<Hash::ConsistentHash> - Contains the entire logics in the XS, leading to it
not being easily usable in other languages, and having a more complicated,
alebit sophisticated, interface.

L<Set::ConsistentHash> - Pure-Perl implementation.

=head1 AUTHORS

=over 4

=item * Eric Herman <eric@freesa.org>

=item * Sawyer X <xsawyerx@cpan.org>

=item * Steffen Mueller <smueller@cpan.org>

=back

