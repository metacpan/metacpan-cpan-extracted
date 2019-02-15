package Data::Graph::Util;

our $DATE = '2019-02-15'; # DATE
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(toposort is_cyclic is_acyclic);

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

1;
# ABSTRACT: Utilities related to graph data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Graph::Util - Utilities related to graph data structure

=head1 VERSION

This document describes version 0.006 of Data::Graph::Util (from Perl distribution Data-Graph-Util), released on 2019-02-15.

=head1 SYNOPSIS

 use Data::Graph::Util qw(toposort is_cyclic is_acyclic);

 # return nodes that satisfy the following graph: a must come before b, b must
 # come before c & d, and d must come before c.

 my @sorted = toposort(
     { a=>["b"], b=>["c", "d"], d=>["c"] },
 ); # => ("a", "b", "d", "c")

 # sort specified nodes (2nd argument) using the graph. nodes not mentioned in
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

=head1 DESCRIPTION

Early release. More functions will be added later.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Graph-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Graph-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Graph-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Graph_(abstract_data_type)>

L<https://en.wikipedia.org/wiki/Topological_sorting#Kahn.27s_algorithm>

L<Algorithm::Dependency> can also do topological sorting, but it is more finicky
with input: graph cannot be epmty and all nodes need to be specified.

L<Sort::Topological> can also sort a DAG, but cannot handle cyclical graph. It
also performs poorly and eats too much RAM on larger graphs.

See L<Bencher::Scenario::GraphTopologicalSortModules> for benchmarks.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
