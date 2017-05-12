#
# This file is part of DBIx-Class-Graph
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package DBIx::Class::Graph::Wrapper;
{
  $DBIx::Class::Graph::Wrapper::VERSION = '1.05';
}

use strict;
use warnings;
use Class::C3;

use base qw/Graph/;
use List::MoreUtils qw(uniq);
use Scalar::Util qw(refaddr);

# $self is an arrayref!

sub _add_edge {
    my $g = shift;
    my ( $from, $to ) = @_;

    die "Please supply two vertices" if ( @_ != 2 );

    $g->add_vertex($from) unless ( $g->has_vertex($from) );
    $g->add_vertex($to)   unless ( $g->has_vertex($to) );
    
    my ( $pkey ) = $from->primary_columns;

    if ( $from->result_source->has_column( $from->_graph_column ) ) {

        # we have no relationship

        $g->delete_edge( $from, $g->successors($from) )
          if ( $from->_connect_by eq "successor"
            && $g->successors($from) );

        $g->delete_edge( $g->predecessors($to), $to )
          if ( $to->_connect_by eq "predecessor"
            && $g->predecessors($to) );

    }

    ( $from, $to ) = ( $to, $from )
      if ( $to->_connect_by eq "predecessor" );

    my $col = $from->_graph_column;
    my $rel    = $from->_graph_rel;
    if ( $from->result_source->relationship_info( $rel )->{attrs}->{accessor} 
        && $from->result_source->relationship_info( $rel )->{attrs}->{accessor} eq 'multi' ) {
        my $column = $from->_graph_foreign_column;
        my $exists = 0;
        foreach my $map ( $from->$rel->all ) {
            ( $map->get_column($column) eq $to->$pkey ) && ( $exists = 1 ) && last;
        }

        if ( $g->is_undirected ) {
            foreach my $map ( $to->$rel->all ) {
                ( $map->get_column($column) eq $from->$pkey )
                  && ( $exists = 1 )
                  && last;
            }
        }

        $from->create_related( $rel, { $column => $to->$pkey } ) unless ($exists);
        
    } else {
        $from->$rel($to);
        $from->update unless($g->[99]);
    }
        
    ( $from, $to ) = ( $to, $from )
      if ( $to->_connect_by eq "predecessor" );
    return $g->next::method( $from, $to );
}

sub delete_edge {
    my $g = shift;
    my ( $from, $to ) = @_;
    $from->throw_exception("need 2 vertices to delete an edge") if ( @_ != 2 );

    my ( $pkey ) = $from->primary_columns;

    my $column = $from->_graph_column;

    ( $from, $to ) = ( $to, $from )
      unless ( $from->_connect_by eq "predecessor" );

    if ( $from->result_source->has_column($column) ) {
        $to->update( { $from->_graph_column => undef } );
    }
    else {
        my $rel = $from->_graph_rel;
        $to->delete_related( $rel,
            { $from->_graph_foreign_column => $from->$pkey } );
    }

    return $g->next::method(@_);
}

sub delete_vertex {
    my $g = shift;
    my $v = shift;
    if ( !$v->_graph_foreign_column ) {
        my @succ =
          ( $v->_connect_by eq "predecessor" )
          ? $g->successors($v)
          : $g->predecessors($v);
        for (@succ) {
            $_->update( { $_->_graph_column => undef } );
        }
    }
    my $e = $g->next::method($v);
    $v->delete;
    return $e;
}

sub get_vertex {
    my $self = shift;
    my $id   = shift;
    my @v    = $self->vertices;
    my ($pkey) = $v[0]->primary_columns;
    for (@v) { return $_ if ( $_->can($pkey) && $_->$pkey eq $id ); }

}

*find_vertex = \&get_vertex;

sub all_successors {
    my $g    = shift;
    my @root = @_;
    my @succ;
    my @return;
    foreach my $succ (@root) {
        push( @succ, $g->successors($succ) );
        @succ = uniq @succ;
    }
    foreach my $succ (@succ) {
        push( @succ, $g->successors($succ) );
        @succ = uniq @succ;
    }
    return @succ;
}

sub all_predecessors {
    my $g    = shift;
    my @root = @_;
    my @pred;
    my @return;
    foreach my $pred (@root) {
        push( @pred, $g->predecessors($pred) );
        @pred = uniq @pred;
    }
    foreach my $pred (@pred) {
        push( @pred, $g->predecessors($pred) );
        @pred = uniq @pred;
    }
    return @pred;
}

sub add_vertex {
    my $self = shift;
    my @v    = @_;
    foreach my $v (@v) {
        $v->insert unless $v->in_storage;
    }
    return $self->next::method(@v);
}

# Preloaded methods go here.
1;


__END__
=pod

=head1 NAME

DBIx::Class::Graph::Wrapper

=head1 VERSION

version 1.05

=head1 DESCRIPTION

Inherits from L<Graph> and overloads some methods to store the data to the database.

=head1 NAME

DBIx::Class::Graph::Wrapper - Subclass of L<Graph>

=head1 SEE ALSO

See L<DBIx::Class::Graph> for details.

=head1 AUTHOR

Moritz Onken, E<lt>onken@houseofdesign.deE<gt>

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

