package Data::RuledCluster::Strategy::List;
use strict;
use warnings;
use parent 'Data::RuledCluster::Strategy';
use Carp ();
use Data::Util qw(is_hash_ref is_array_ref);

sub resolve {
    my ($class, $resolver, $node_or_cluster, $args) = @_;

    my @keys = $class->keys_from_args($args);
    my $key  = shift @keys;

    if ( not exists $args->{list_map} ) {
        if ( not exists $args->{strategy_config} && is_hash_ref( $args->{strategy_config} ) ) {
            Carp::croak('strategy_config is not exists or is not hash ref');
        }

        my $strategy_config = $args->{strategy_config};
        $args->{list_map} = +{
            map {
                my $node = $_;
                map { $_ => $node } @{ $args->{strategy_config}->{$node} }
            }
            grep { length $_ > 0 }
            keys %$strategy_config
        };
        if ( exists $strategy_config->{""} ) {
            $args->{list_fallback} ||= $strategy_config->{""};
        }
    }

    if ( !exists $args->{list_fallback} && !exists $args->{list_map}->{$key} ) {
        Carp::croak(sprintf("Not exists fallback, The key '%d' has not route", $key ));
    }

    my $resolved_node;
    if ( exists $args->{list_map}->{$key} ) {
        $resolved_node = $args->{list_map}{$key};
    }
    else {
        $resolved_node = $args->{list_fallback};
        unshift( @keys, $key );
    }

    return ( $resolved_node, @keys );
}

1;

