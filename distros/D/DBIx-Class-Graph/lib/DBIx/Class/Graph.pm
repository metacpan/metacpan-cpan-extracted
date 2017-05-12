#
# This file is part of DBIx-Class-Graph
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package DBIx::Class::Graph;
{
  $DBIx::Class::Graph::VERSION = '1.05';
}

use Moose;
extends 'DBIx::Class';
with 'DBIx::Class::Graph::Role::Result';

__PACKAGE__->mk_classdata("_graph_rel");
__PACKAGE__->mk_classdata("_graph_foreign_column");
__PACKAGE__->mk_classdata("_graph_column");
__PACKAGE__->mk_classdata("_graph");
__PACKAGE__->mk_classdata("_connect_by");

1;



=pod

=head1 NAME

DBIx::Class::Graph

=head1 VERSION

version 1.05

=head1 SYNOPSIS

  package MySchema::Graph;
  
  use base 'DBIx::Class';
  
  __PACKAGE__->load_components("Graph", "Core");
  __PACKAGE__->table("tree");
  __PACKAGE__->add_columns("id", "name", "parent_id");

  __PACKAGE__->connect_graph(predecessor => "parent_id");

  my @children = $rs->get_vertex($id)->successors;
  
  my @vertices = $rs->vertices;
  
  # do other cool stuff like calculating distances etc.

=head1 DESCRIPTION

This module allows to create and interact with a directed graph. It will take care of storing the information in a relational database.
It uses L<Graph> for calculations.
This module extends the DBIx::Class::ResultSet. Some methods are added to the resultset, some to the row objects.

=head1 NAME

DBIx::Class::Graph - Represent a graph in a relational database using DBIC

=head1 CONFIGURATION

=head2 load_components

  __PACKAGE__->load_components(qw(Graph Core));

To use this module it has to loaded via C<load_components> in the result class.

=head2 resultset_class

XXX

=head2 connect_graph(@opt)

    __PACKAGE__->connect_graph( predecessor => 'parent_id' );
    __PACKAGE__->connect_graph( successor   => 'child_id' );
    __PACKAGE__->connect_graph( predecessor => { parents => 'parent_id' } );
    __PACKAGE__->connect_graph( successor   => { childs => 'child_id' } );

The first argument defines how the tree is build. You can either specify C<predecessor> or C<successor>.

The name of the relation to the next vertex is defined by the second argument.

=head1 METHODS

=head2 ResultSet methods

=head3 get_vertex($id)

finds a vertex by searching the underlying resultset for C<$id> in the primary key column (only single primary keys are supported). It's not as smart as the original L<DBIx::Class::ResultSet/find> because it looks on the primary key(s) for C<$id> only.

=head2 Result methods

The following methods are imported from L<Graph>:

  delete_vertex connected_component_by_vertex biconnected_component_by_vertex
  weakly_connected_component_by_vertex strongly_connected_component_by_vertex
  is_sink_vertex is_source_vertex is_successorless_vertex is_successorful_vertex
  is_predecessorless_vertex is_predecessorful_vertex is_isolated_vertex is_interior
  is_exterior is_self_loop_vertex successors neighbours predecessors degree
  in_degree out_degree edges_at edges_from edges_to get_vertex_count random_successor
  random_predecessor vertices_at

=head1 FAQ

=head2 How do I sort the nodes?

Simply sort the resultset

  $rs->search(undef, {order_by => "title ASC"})->graph;

=head1 CAVEATS

=head2 Multigraph

Multipgraphs are not supported. This means you there can only be one edge per vertex pair and direction.

=head2 Speed

you should consider caching the L<Graph> object if you are working with large number of vertices.

=head1 SEE ALSO

L<DBIx::Class::Tree>, L<DBIx::Class::NestedSet>

=head1 BUGS

See L</"CAVEATS">

=head1 AUTHOR

Moritz Onken, E<lt>onken@houseofdesign.deE<gt>

I am also avaiable on the DBIx::Class mailinglist

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Moritz Onken

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

