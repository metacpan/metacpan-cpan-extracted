#
# This file is part of DBIx-Class-Graph
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package DBIx::Class::Graph::Role::Result;
{
  $DBIx::Class::Graph::Role::Result::VERSION = '1.05';
}

use strict;
use warnings;
use Moose::Role;
  
has _graph => ( is => 'rw' );

my @_import_methods =
  qw(delete_vertex connected_component_by_vertex biconnected_component_by_vertex
  weakly_connected_component_by_vertex strongly_connected_component_by_vertex
  is_sink_vertex is_source_vertex is_successorless_vertex is_successorful_vertex
  is_predecessorless_vertex is_predecessorful_vertex is_isolated_vertex is_interior
  is_exterior is_self_loop_vertex successors neighbours predecessors degree
  in_degree out_degree edges_at edges_from edges_to get_vertex_count random_successor
  random_predecessor vertices_at);

foreach my $method (@_import_methods) {
    __PACKAGE__->meta->add_method(
        $method => sub {
            my $self = shift;
            $self->throw_exception(
                q('->graph' has to be called on the resultset first))
              unless ( $self->_graph );
            return $self->_graph->$method($self);
        }
    );
}

sub connect_graph {
    my $class = shift;
    my $rel  = shift;
    my $col  = shift;
    if ( ref $col eq "HASH" ) {
        $class->_graph_foreign_column( values %$col );
        ($col) = keys %$col;
    }
    $class->_graph_rel($col);
    my ( $pkey, $too_much ) = $class->primary_columns
      or
      $class->throw_exception( $class . ' requires a primary key column' );
    $class->throw_exception( $class
          . ' does not support result classes with more than one primary key' )
      if ($too_much);
    $class->throw_exception(q(wrong syntax for connect_graph))
      unless ( grep { $_ eq $rel } qw(predecessor successor) );
    $class->_connect_by($rel);
    $class->_graph_column($col);
    if ( $class->has_column($col) ) {
        $class->belongs_to(
            "_graph_relationship" => $class =>
              { "foreign." . $pkey => "self." . $col },
            { join_type            => 'left' }
        );
        $class->_graph_rel("_graph_relationship");
    }

    $class->resultset_class('DBIx::Class::ResultSet::Graph')
      unless $class->resultset_class->isa('DBIx::Class::ResultSet::Graph');

}

1;

__END__
=pod

=head1 NAME

DBIx::Class::Graph::Role::Result

=head1 VERSION

version 1.05

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

