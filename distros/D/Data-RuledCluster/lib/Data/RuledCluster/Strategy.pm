package Data::RuledCluster::Strategy;
use strict;
use warnings;
use Carp;
use Data::Util qw(is_array_ref);

sub resolve { Carp::croak('Not implement') }

sub resolve_node_keys {
    my ($class, $resolver, $cluster_or_node, $args, $options) = @_;

    my %node_keys;
    for my $key ($class->keys_from_args($args)) {
        my %args = %$args;
        $args{key} = $key;

        my ($resolved, @keys) = $class->resolve($resolver, $cluster_or_node, \%args, $options);

        my $node_keys = $node_keys{ $resolved } ||= [];
        if ($resolver->is_cluster($resolved)) {
            push @$node_keys, {
                root => $key,
                next => \@keys,
            };
        }
        else {
            push @$node_keys, $key;
        }
    }

    return %node_keys;
}

sub keys_from_args {
    my ( $class, $args ) = @_;
    return is_array_ref( $args->{key} ) ? @{ $args->{key} } : ( $args->{key} );
}

1;

