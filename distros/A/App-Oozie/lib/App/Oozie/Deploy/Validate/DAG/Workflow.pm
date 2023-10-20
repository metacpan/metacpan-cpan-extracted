package App::Oozie::Deploy::Validate::DAG::Workflow;
$App::Oozie::Deploy::Validate::DAG::Workflow::VERSION = '0.010';
use 5.014;
use strict;
use warnings;
use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Deploy::Validate::DAG::Vertex;

use Carp ();
use Graph::Directed;
use Moo;
use Ref::Util       qw( is_hashref );
use Types::Standard qw( HashRef    );
use XML::LibXML;

with qw(
    App::Oozie::Role::Log
);

has node_types => (
    is      => 'ro',
    isa     => HashRef,
    default => sub {
        +{
            action   => { to => [ 'ok.to', 'error.to' ] },
            decision => { to => [ 'switch/case.to', 'switch/default.to' ] },
            end      => {},
            fork     => { to => 'path.start' },
            join     => { to => 'to' },
            kill     => {},
            start    => { vname => 'start', to => 'to' },
        }
    },
);

has current_graph => (
    is      => 'rw',
    default => sub {},
);

has current_nodes => (
    is      => 'rw',
    default => sub {},
);

has current_vertices => (
    is      => 'rw',
    default => sub {},
);

has graph_filename => (
    is      => 'rw',
    default => sub { 'graph.png' },
);

has _vertex_lookup => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

sub assert {
    my $self = shift;
    my $file = shift;
    my @errors = $self->validate( $file );

    if ( @errors ) {
        $self->logger->fatal( "Some errors were encountered." );
        for my $error (@errors) {
            $self->logger->fatal( $error->[0] );
            $self->logger->fatal( $error->[1] );
        }
        die "Errors found, aborting.\n";
    }

    $self->logger->info( "$file validated OK" );

    return;
}

sub validate {
    my $self = shift;
    my $file = shift || die "No file was specified!";

    $self->logger->info( "DAG validation for $file" );

    die "File $file does not exist" if ! -e $file;

    my $xml  = XML::LibXML->load_xml( location => $file );
    my $root = $xml->getDocumentElement;

    my($all_nodes, $all_vertices) = $self->_descend( $root );

    my $g = Graph::Directed->new( refvertexed_stringified => 1 );

    my @errors;
    for my $v ( values %{ $all_vertices } ) {
        for my $to ( @{ $v->{data}{to} || [] } ) {
            if ( !$all_vertices->{$to} ) {
                push @errors,
                    [
                    "vertex $v has an edge to $to, which doesn't exist",
                    "nodes cannot reference nodes that do not exist in the workflow"
                    ];
                next;
            }
            $g->add_edge( $v, $all_vertices->{$to} );
        }
    }

    if ( !$g->is_dag ) {
        push @errors,
            [
            "graph is not a DAG",
            "an oozie workflow should always be a directed acyclic graph; why this one isn't can probably be found in the next errors"
            ];
    }

    if ( my @cycle = $g->find_a_cycle ) {
        push @errors,
            [
            "at least one cycle found: " . join( ' -> ', @cycle ),
            "since an oozie workflow is a DAG, there should be no cycles (loops)"
            ];
        }

    if ( !$g->is_weakly_connected ) {
        push @errors,
            [
            "graph is not fully connected",
            "no node should be on its own; all nodes should descend from the 'start' or one of its descendents"
            ];
    }

    for ( $g->source_vertices ) {
        next if "$_" eq "start";
        push @errors,
            [
            "extra source vertex found: \"$_\"",
            "means that this node pretends to have no ancestor; all nodes should descend at least from 'start'"
            ];
    }

    for my $e ( $g->successorless_vertices ) {
        my $type =  is_hashref( $e ) ? $e->{data}{type} : '';
        next if $type && $type =~ /^(end|kill)$/;
        push @errors,
            [
                "extra successorless vertex found: \"$e\"",
                "means that this node pretends to have no descendent; all nodes should at least be ancestors of 'end' or 'kill'"
            ];
    }

    my $reachable_total = $g->all_reachable('start');
    my $available_total = (scalar keys %{ $all_vertices } ) - 1;

    if ( $reachable_total != $available_total ) {
        push @errors,
            [
                sprintf(
                    "out of %s vertices, only %s are reachable",
                        $available_total,
                        $reachable_total,
                ),
                "means that not all nodes are reachable from the 'start' node",

            ];
    }

    $self->current_graph(    $g            );
    $self->current_nodes(    $all_nodes    );
    $self->current_vertices( $all_vertices );

    return @errors;
}

sub _descend {
    my $self         = shift;
    my $node         = shift;
    my $all_nodes    = shift || [];
    my $all_vertices = shift || {};
    my $node_types   = $self->node_types;

    for my $type ( keys %{ $node_types } ) {
        for my $kid ( $node->getChildrenByLocalName( $type ) ) {
            $self->_descend( $kid, $all_nodes, $all_vertices );
        }
    }

    my $processor = $node_types->{ $node->localname() }
        || return $all_nodes, $all_vertices;

    if ( !ref $processor->{to} ) {
        $processor->{to} = [ $processor->{to} // () ];
    }

    my(@node_to, $nn);

    if ( @{ $processor->{to} } > 0 ) {
        for my $to ( grep { $_ } @{ $processor->{to} } ) {
            if ( $to =~ /^(.+?)\.(.+?)$/ ) {
                my ( $child_tag, $child_attr ) = ( $1, $2 );
                my @child_nodes;
                if ($child_tag =~ /^(.+)\/(.+)$/) {
                    @child_nodes = map { $_->getChildrenByLocalName($2) }
                                    $node->getChildrenByLocalName($1);
                }
                else {
                    @child_nodes = $node->getChildrenByLocalName($child_tag);
                }
                push @node_to, $_->getAttribute($child_attr) for @child_nodes;
            }
            else {
                push @node_to, $node->getAttribute($to);
            }
        }
    }
    else {
        $nn = @node_to ? undef : $node->localname;
    }

    my $vname = $processor->{vname} || $node->getAttribute("name");

    if ( $self->_vertex_lookup->{ $vname }++ > 1 ) {
        Carp::confess "Vertex already created by that name: $vname";
    }

    $all_vertices->{ $vname }
        = App::Oozie::Deploy::Validate::DAG::Vertex->new(
                name => $vname,
                data => {
                    to   => [@node_to],
                    ($nn ? (
                    type => $nn,
                    ) : () )
                },
            );

    # keep this for debugging
    push @{ $all_nodes }, [ $vname, [@node_to] ];

    return $all_nodes, $all_vertices;
}

sub dump_graph {
    my $self = shift;
    my $type = shift || die "No type was defined!";
    my $sub  = $self->can('_dump_' . $type ) || die "$type is not a valid type";
    $self->$sub();
}

sub _dump_perl {
    my $self      = shift;
    my $g         = $self->current_graph || die "current_graph is not set!";
    my $all_nodes = $self->current_nodes || die "current_nodes is not set";

    my $debug = {
        nodes => $all_nodes,
        graph => $g,
    };

    require Data::Dumper;
    my $d = Data::Dumper->new([ $debug ], [ 'graph' ]);
    $self->logger->debug( $d->Dump );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Deploy::Validate::DAG::Workflow

=head1 VERSION

version 0.010

=head1 SYNOPSIS

=head1 DESCRIPTION

Used by Oozie deploy tool to prevent mistakes before submission. 
Checks the workflow is a properly formed DAG.

=head1 NAME

App::Oozie::Deploy::Validate::DAG::Workflow - Part of the Oozie workflow DAG validator.

=head1 Methods

=head2 assert

=head2 current_graph

=head2 current_nodes

=head2 current_vertices

=head2 dump_graph

=head2 graph_filename

=head2 node_types

=head2 validate

=head1 Possible Extensions

    sub _dump_graphviz {
        my $self = shift;
        my $g    = $self->current_graph || die "current_graph is not set!";
        my $file = $self->graph_filename;

        require Graph::Writer::GraphViz;

        Graph::Writer::GraphViz->new(
            -edge_color => 1,
            -fontsize   => 8,
            -format     => 'png',
            -layout     => 'twopi',
            -node_color => 2,
            -ranksep    => 1.5,
        )->write_graph( $g, $file );

        $self->logger->info( "$file is created." );

        return;
    }

    sub _dump_d3 {
        my $self = shift;
        my $g    = $self->current_graph || die "current_graph is not set!";
        require Graph::D3;
        my $d3 = Graph::D3->new(
                    graph => $g,
                    type  => 'json',
                );
        print $d3->force_directed_graph;
    }

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
