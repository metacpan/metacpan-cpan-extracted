package Data::RuledCluster::Strategy::Formatted;
use strict;
use warnings;
use parent 'Data::RuledCluster::Strategy';
use Data::Util qw(is_number neat);
use Carp ();

sub resolve {
    my ( $class, $resolver, $node_or_cluster, $args ) = @_;

    my @keys = $class->keys_from_args($args);
    my $key = shift @keys;

    unless ( is_number($key) ) {
        Carp::croak(
            sprintf('args has not key field or no number value (key: %s)', neat($key))
        );
    }

    my $node_format = $args->{node_format}
        or Carp::croak('node_format settings must be required');

    my @nodes = $resolver->clusters($node_or_cluster);
    my $expected_node = sprintf($node_format, $key);
    unless (grep {$_ eq $expected_node} @nodes) {
        Carp::croak(sprintf('%s node is not exists', $expected_node));
    }
    return ($expected_node, @keys);
}

1;

__END__

