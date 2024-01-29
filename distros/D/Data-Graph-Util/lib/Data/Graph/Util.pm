package Data::Graph::Util;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-20'; # DATE
our $DIST = 'Data-Graph-Util'; # DIST
our $VERSION = '0.007'; # VERSION

our @EXPORT_OK = qw(
                       toposort
                       is_cyclic
                       is_acyclic
                       connected_components
               );

sub _toposort {
    my $graph = shift;

    # this is the Kahn algorithm, ref:
    # https://en.wikipedia.org/wiki/Topological_sorting#Kahn.27s_algorithm

    my %in_degree;
    for my $k (keys %$graph) {
        $in_degree{$k} //= 0;
        for (@{ $graph->{$k} }) { $in_degree{$_}++ }
    }

    # collect nodes with no incoming edges (in_degree = 0)
    my @S;
    for (sort keys %in_degree) { unshift @S, $_ if $in_degree{$_} == 0 }

    my @L;
    while (@S) {
        my $n = pop @S;
        push @L, $n;
        for my $m (@{ $graph->{$n} }) {
            if (--$in_degree{$m} == 0) {
                unshift @S, $m;
            }
        }
    }

    if (@L == keys(%$graph)) {
        if (@_) {
            no warnings 'uninitialized';
            # user specifies a list to be sorted according to @L. this is like
            # Sort::ByExample but we implement it ourselves to avoid dependency.
            my %pos;
            for (0..$#L) { $pos{$L[$_]} = $_+1 }
            return (0, [
                sort { ($pos{$a} || @L+1) <=> ($pos{$b} || @L+1) } @{$_[0]}
            ]);
        } else {
            return (0, \@L);
        }
    } else {
        # there is a cycle
        return (1, \@L);
    }
}

sub toposort {
    my ($err, $res) = _toposort(@_);
    die "Can't toposort(), graph is cyclic" if $err;
    @$res;
}

sub is_cyclic {
    my ($err, $res) = _toposort(@_);
    $err;
}

sub is_acyclic {
    my ($err, $res) = _toposort(@_);
    !$err;
}

sub connected_components {
    my $graph = shift;

    # create a map of bidirectional connections between nodes, to ease checking
    my %connections;
    for my $node1 (keys %$graph) {
        for my $node2 (@{ $graph->{$node1} }) {
            $connections{$node1}{$node2} = 1;
            $connections{$node2}{$node1} = 1;
        }
    }

    my @subgraphs;
    my %remaining_nodes = %$graph;

    # traverse a node to get a subgraph. remove the nodes from the original
    # graph. repeat until there are no nodes left on the original graph.

    while (1) { # while there are still unlabeled nodes
        my ($node1, $dependants1) = each %remaining_nodes or last;

        my $subgraph = {$node1 => $dependants1};
        my %seen;
        my @nodes_to_check = keys %{ $connections{$node1} };

        while (@nodes_to_check) { # while we can still find nodes connected to the subgraph
            my $node2 = shift @nodes_to_check;
            next if $seen{$node2}++;
            if (my $dependants2 = delete $remaining_nodes{$node2}) {
                $subgraph->{$node2} = $dependants2;
                push @nodes_to_check, keys %{ $connections{$node2} };
            }
        }

        push @subgraphs, $subgraph;
    }

    sort { scalar(keys %$b) <=> scalar(keys %$a) } @subgraphs;
}

1;
# ABSTRACT: Utilities related to graph data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Graph::Util - Utilities related to graph data structure

=head1 VERSION

This document describes version 0.007 of Data::Graph::Util (from Perl distribution Data-Graph-Util), released on 2023-12-20.

=head1 SYNOPSIS

 use Data::Graph::Util qw(
     toposort
     is_cyclic
     is_acyclic
     connected_components
 );

 # return nodes of a graph. a must come before b, b must come before c & d, and
 # d must come before c.

 my @sorted = toposort(
     { a=>["b"], b=>["c", "d"], d=>["c"] },
 ); # => ("a", "b", "d", "c")

 # sort nodes specified in 2nd argument using the graph. nodes not mentioned in
 # the graph will be put at the end. duplicates are not removed.

 my @sorted = toposort(
     { a=>["b"], b=>["c", "d"], d=>["c"] },
     ["e", "a", "b", "a"]
 ); # => ("a", "a", "b", "e")

 # check if a graph is cyclic

 say is_cyclic ({a=>["b"]}); # => 0
 say is_acyclic({a=>["b"]}); # => 1

 # check if a graph is acyclic (not cyclic)

 say is_cyclic ({a=>["b"], b=>["c"], c=>["a"]}); # => 1
 say is_acyclic({a=>["b"], b=>["c"], c=>["a"]}); # => 0

 # return connected subgraphs, sorted by the largest
 my @subgraphs = connected_components(
     { a=>["b"], b=>["c", "d"], d=>["c"] },
 ); # => return 1 element, all nodes are connected as a single graph

 # return connected subgraphs, sorted by the largest
 my @subgraphs = connected_components(
     { a=>["b"], b=>["c", "d"], d=>["c"],
       e=>["f"],
       g=>["h", "i"], j=>["a"],
     },
 ); # => return 3 elements, there are 3 separate subgraphs
    # ({a=>["b"], b=>["c", "d"], d=>["c"], j=>["a"]}, {e=>["f"]}, {g=>["h","i"]})

=head1 DESCRIPTION

Early release. More functions will be added later.

This module provides some functions related to the graph data structure.

Keywords: topological ordering, dependency sorting, dependency ordering.

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 toposort

Usage:

 toposort(\%graph[ , \@nodes ]) => sorted list

Perform a topological sort on graph (currently using the Kahn algorithm). Will
return the nodes of the graph sorted topologically. Will die if graph cannot be
sorted, e.g. when graph is cyclic.

If C<\@nodes> is specified, will instead return C<@nodes> sorted according to
the topological order. Duplicates are allowed and not removed. Nodes not
mentioned in graph are also allowed and will be put at the end.

=head2 is_cyclic

Usage:

 is_cyclic(\%graph) => bool

Return true if graph contains at least one cycle. Currently implemented by
attempting a topological sort on the graph. If it can't be performed, this means
the graph contains cycle(s).

=head2 is_acyclic

Usage:

 is_acyclic(\%graph) => bool

Return true if graph is acyclic, i.e. contains no cycles. The opposite of
L</is_cyclic>.

=head2 connected_components

Usage:

 connected_components(\%graph) => list of subgraphs

Return list of subgraphs that are not connected to one another, sorted by
descending size. If all the nodes are connected, will return a single subgraph
(the original graph itself).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Graph-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Graph-Util>.

=head1 SEE ALSO

=head2 Articles

L<https://en.wikipedia.org/wiki/Graph_(abstract_data_type)>

L<https://en.wikipedia.org/wiki/Topological_sorting#Kahn.27s_algorithm>

=head2 Related modules

L<Graph> contains more graph-related algorithms.

=head3 Topological sort

L<Algorithm::Dependency> can also do topological sorting, but it is more finicky
with input: graph cannot be epmty and all nodes need to be specified.

L<Sort::Topological> can also sort a DAG, but cannot handle cyclical graph. It
also performs poorly and eats too much RAM on larger graphs.

See L<Bencher::Scenario::GraphTopologicalSortModules> for benchmarks.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Jose Luis Martínez Torres

Jose Luis Martínez Torres <joseluis.martinez@capside.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2019, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Graph-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
