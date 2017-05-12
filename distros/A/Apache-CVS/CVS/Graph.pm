# $Id: Graph.pm,v 1.2 2002/11/12 03:36:40 barbee Exp $

=head1 NAME

Apache::CVS::Graph - class that implements a graph that details the revision
history of an C<Apache::CVS::File>

=head1 SYNOPSIS

 use Apache::CVS::File();
 use Apache::CVS::Graph();
 use Graph::Directed();
 
 $file = Apache::CVS::File->new($path, $rcs_config);
 $cvs_graph = Apache::CVS::Graph->new($file);
 $graph = $cvs_graph->graph();
 @vertices = $graph->vertices();

=head1 DESCRIPTION

The C<Apache::CVS::Graph> class implements a directed acyclick graph that
details the revision history of an C<Apache::CVS::File>.

=over 4

=cut

package Apache::CVS::Graph;
use strict;

use Rcs();
use Graph::Directed();
use Apache::CVS::File;

$Apache::CVS::Graph::VERSION = $Apache::CVS::VERSION;;

=item Apache::CVS::Graph->new($file)

Construct a new C<Apache::CVS::Graph> object. Takes an C<Apache::CVS::File>
as an argument.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self;
 
    $self->{file} = shift;
    $self->{graph} = undef;
    $self->{labels} = {};
    bless ($self, $class);
    return $self;
}

=item $cvs_graph->file()

Set or get the C<Apache::CVS::File> associated with this graph.

=cut

sub file {
    my $self = shift;
    $self->{file} = shift if scalar @_;
    return $self->{file};
}

=item $cvs_graph->graph()

Returns a C<Graph::Directed> object.

=cut

sub graph {
    my $self = shift;
    $self->{graph} = shift if scalar @_;
    # must used defined since Graph overloads double quotes.
    $self->_load() unless defined($self->{graph});
    return $self->{graph};
}

=item $cvs_graph->root_node()

Get the root node for this graph. There are instances where $G->source_vertices() does not return something useful.

=cut

sub root_node {
    return '1.1';
}

=item $cvs_graph->labels()

Get or set the labels for this graph.

=cut

sub labels {
    my $self = shift;
    $self->{labels} = shift if scalar @_;
    $self->_load() unless $self->{labels};
    return $self->{labels};
}

sub _resolve_version {
    my $number = shift;
    $number =~ s#1\.1(\.1)*#1\.1#;
    $number =~ s#\.0\.\d+$##;
    return $number;
}

sub _create_vertex {
    my $self = shift;
    my $vertex_id = shift;
    my $parent_id = $vertex_id;

    my $graph = $self->graph();

    return if $graph->has_vertex($vertex_id);

    # base case
    if ($vertex_id eq '1.1') {
        $graph->add_vertex($vertex_id);
        return $vertex_id;
    }

    # if revision isn't x.1, then the parent is one fewer.
    if ($vertex_id =~ /(?<=\.)(\d{2,}|[^1])$/) {
        # $& should only include the trailing '1'
        my $minus_one = $& - 1;
        $parent_id = $` . $minus_one;
    # otherwise this is the first branch revision, so the parent is the branch
    # root revision
    } else {
        $parent_id =~ s#(\.\d){2}$##;
    }
    $self->_create_vertex($parent_id);
    $graph->add_vertex($vertex_id);
    $graph->add_path($parent_id, $vertex_id);
}

sub _load {
    my $self = shift;
    die "No version file to graph." unless $self->file();

    my $labels = {};
    $self->graph(Graph::Directed->new());

    my @revisions = $self->file()->rcs()->revisions();
    foreach my $rev (@revisions) {
        my @symbols = $self->file()->rcs()->symbol($rev);
        my $resolved_version = _resolve_version($rev);
        $self->_create_vertex($resolved_version);
        push @{ $labels->{$resolved_version} }, @symbols;
    }
    $self->labels($labels);
}

=back

=head1 SEE ALSO

L<Apache::CVS>, L<Apache::CVS::File>, L<Graph::Directed>,
L<Graph::Base>, L<Rcs>

=head1 AUTHOR

John Barbee <F<barbee@veribox.net>>

=head1 COPYRIGHT

Copyright 2001-2002 John Barbee

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
