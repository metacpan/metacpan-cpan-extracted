package Data::RuledCluster::Strategy::Key;
use strict;
use warnings;
use parent 'Data::RuledCluster::Strategy';
use Data::Util qw(is_number neat);

sub resolve {
    my ( $class, $resolver, $node_or_cluster, $args ) = @_;

    my @keys = $class->keys_from_args($args);
    my $key = shift @keys;

    unless ( is_number($key) ) {
        Carp::croak(
            sprintf('args has not key field or no number value (key: %s)', neat($key))
        );
    }

    my @nodes         = $resolver->clusters($node_or_cluster);
    my $resolved_node = $nodes[ $key % scalar @nodes ];

    return ($resolved_node, @keys);
}

1;

