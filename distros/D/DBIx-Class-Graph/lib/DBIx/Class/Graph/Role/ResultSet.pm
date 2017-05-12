#
# This file is part of DBIx-Class-Graph
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package DBIx::Class::Graph::Role::ResultSet;
{
  $DBIx::Class::Graph::Role::ResultSet::VERSION = '1.05';
}

use strict;
use warnings;
use Moose::Role;
use DBIx::Class::Graph::Wrapper;

use Scalar::Util qw(weaken);

has _graph => (
    is         => 'rw',
    isa        => 'DBIx::Class::Graph::Wrapper',
    lazy_build => 1,
    handles    => \&_import_methods
);
has _graph_rel => ( is => 'rw' );

sub _import_methods {
    return map { $_ => $_ }
        grep { $_ ne 'new' && $_ !~ /^_/ && !__PACKAGE__->can($_) }
        $_[1]->get_all_method_names;
}

sub _build__graph {
    my $self   = shift;
    my $source = $self->result_class;
    my ($pkey) = $source->primary_columns;
    my $rel    = $source->_graph_rel;
    my @obj    = $self->search( undef, { prefetch => $rel } )->all;
    $self->set_cache( \@obj );
    my $g = DBIx::Class::Graph::Wrapper->new( refvertexed => 1 );

    for (@obj) {
        $g->add_vertex($_);
        $_->_graph($g);
        weaken( $_->{_graph} );

    }

    $g->[99] = 1;
    foreach my $row (@obj) {
        my ( $from, $to ) = ();
        my $col = $source->_graph_column;
        if ( $row->result_source->has_column($col) ) {
            next
                unless ( my $pre
                = { $row->get_columns }->{ $source->_graph_column } );
            ( $from, $to )
                = ( $g->get_vertex( $row->$pkey ), $g->get_vertex($pre) );
            next unless $from && $to;

            ( $from, $to ) = ( $to, $from )
                if $source->_connect_by eq "predecessor";
            $g->add_edge( $from, $to );
        }
        else {
            foreach my $pre ( $row->$rel->all ) {
                ( $from, $to ) = (
                    $g->get_vertex( $row->$pkey ),
                    $g->get_vertex(
                        { $pre->get_columns }
                        ->{ $source->_graph_foreign_column }
                    )
                );
                next unless $from && $to;
                ( $from, $to ) = ( $to, $from )
                    if $source->_connect_by eq "predecessor";
                $g->add_edge( $from, $to );

            }
        }

    }
    $g->[99] = 0;
    return $g;
}

1;

__END__
=pod

=head1 NAME

DBIx::Class::Graph::Role::ResultSet

=head1 VERSION

version 1.05

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

