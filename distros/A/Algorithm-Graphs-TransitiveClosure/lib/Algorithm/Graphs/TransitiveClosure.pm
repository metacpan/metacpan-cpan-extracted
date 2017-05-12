package Algorithm::Graphs::TransitiveClosure;

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use Exporter ();

our @ISA       = qw /Exporter/;
our @EXPORT    = qw //;
our @EXPORT_OK = qw /floyd_warshall/;

our $VERSION   = '2009110901';


sub floyd_warshall ($) {
    my $graph = shift;
    if (ref $graph eq 'HASH') {
        my @vertices = keys %{$graph};

        foreach my $k (@vertices) {
            foreach my $i (@vertices) {
                foreach my $j (@vertices) {
                    # Don't use ||= here, to avoid autovivication.
                    $graph -> {$i} -> {$j} = 1 if $graph -> {$k} -> {$j} &&
                                                  $graph -> {$i} -> {$k};
                }
            }
        }
    }
    elsif (ref $graph eq 'ARRAY') {
        my $count = @{$graph};
        for (my $k = 0; $k < $count; $k ++) {
            for (my $i = 0; $i < $count; $i ++) {
                for (my $j = 0; $j < $count; $j ++) {
                    $graph -> [$i] -> [$j] ||= $graph -> [$k] -> [$j] &&
                                               $graph -> [$i] -> [$k];
                }
            }
        }
    }

    $graph;
}

1;

__END__


=head1 NAME

Algorithm::Graphs::TransitiveClosure - Calculate the transitive closure.

=head1 SYNOPSIS

    use Algorithm::Graphs::TransitiveClosure qw /floyd_warshall/;

    my $graph = [[1, 0, 0, 0], [0, 1, 1, 1], [0, 1, 1, 0], [1, 0, 1, 1]];
    floyd_warshall $graph;
    print "There is a path from 2 to 0.\n" if $graph -> [2] -> [0];

    my $graph2 = {one   => {one => 1},
                  two   => {two => 1, three => 1, four => 1},
                  three => {two => 1, three => 1},
                  four  => {one => 1, four  => 1}};
    floyd_warshall $graph2;
    print "There is a path from three to one.\n" if
        $graph2 -> {three} -> {one};

=head1 DESCRIPTION

This is an implementation of the well known I<Floyd-Warshall> algorithm. [1,2]

The subroutine C<floyd_warshall> takes a directed graph, and calculates
its transitive closure, which will be returned. The given graph is
actually modified, so be sure to pass a copy of the graph to the routine
if you need to keep the original graph.

The subroutine takes graphs in one of the two following formats:

=over

=item floyd_warshall ARRAYREF

The graph I<G = (V, E)> is described with a list of lists, C<$graph>,
representing I<V x V>. If there is an edge between vertices C<$i> and
C<$j> (or if C<$i == $j>), then C<$graph -E<gt> [$i] -E<gt> [$j] == 1>. For all
other pairs C<($k, $l)> from I<V x V>, C<$graph -E<gt> [$k] -E<gt> [$l] == 0>.

The resulting C<$graph> will have C<$graph -E<gt> [$i] -E<gt> [$j] == 1> iff
C<$i == $j> or there is a path in I<G> from C<$i> to C<$j>, and
C<$graph -E<gt> [$i] -E<gt> [$j] == 0> otherwise.

=item floyd_warshall HASHREF

The graph I<G = (V, E)>, with labeled vertices, is described with
a hash of hashes, C<$graph>, representing I<V x V>. If there is an
edge between vertices C<$label1> and C<$label2> (or if C<$label1 eq $label2>),
then C<$graph -E<gt> {$label1} -E<gt> {$label2} == 1>. For all other pairs
C<($label3, $label4)> from I<V x V>, C<$graph -E<gt> {$label3} -E<gt> {$label4}>
does not exist.

The resulting C<$graph> will have
C<$graph -E<gt> {$label1} -E<gt> {$label2} == 1>
iff C<$label1 eq $label2> or there is a path in I<G> from
C<$label1> to C<$label2>, and C<$graph -E<gt> {$label1} -E<gt> {$label2}>
does not exist otherwise.

=back

=head1 EXAMPLES

    my $graph = [[1, 0, 0, 0],
                 [0, 1, 1, 1],
                 [0, 1, 1, 0],
                 [1, 0, 1, 1]];
    floyd_warshall $graph;
    foreach my $row (@$graph) {print "@$row\n"}

    1 0 0 0
    1 1 1 1
    1 1 1 1
    1 1 1 1

    my $graph = {one   => {one => 1},
                 two   => {two => 1, three => 1, four => 1},
                 three => {two => 1, three => 1},
                 four  => {one => 1, three => 1, four => 1}};
    floyd_warshall $graph;
    foreach my $l1 (qw /one two three four/) {
        print "$l1: ";
        foreach my $l2 (qw /one two three four/) {
            next if $l1 eq $l2;
            print "$l2 " if $graph -> {$l1} -> {$l2};
        }
        print "\n";
    }

    one: 
    two: one three four 
    three: one two four 
    four: one two three 

=head1 COMPLEXITY

The running time of the algorithm is cubed in the number of vertices of the
graph. The author of this package is not aware of any faster algorithms,
nor of a proof if this is optimal. Note than in specific cases, when
the graph can be embedded on surfaces of bounded genus, or in the case
of sparse connection matrices, faster algorithms than cubed in the number
of vertices exist. 

The space used by this algorithm is at most quadratic in the number of
vertices, which is optimal as the resulting transitive closure can have
a quadratic number of edges. In case when the graph is represented as a
list of lists, the quadratic bound will always be achieved, as the list
of lists already has that size. The hash of hashes however will use space
linear to the size of the resulting transitive closure.

=head1 LITERATURE

The Floyd-Warshall algorithm is due to Floyd [2], and based on a
theorem of Warshall [3]. The implemation of this package is based on an
implementation of Floyd-Warshall found in Cormen, Leiserson and Rivest [1].

=head1 REFERENCES

=over

=item [1]

Thomas H. Cormen, Charles E. Leiserson and Ronald L. Rivest:
I<Introduction to Algorithms>. Cambridge: MIT Press, B<1990>.
ISBN 0-262-03141-8.

=item [2]

Robert W. Floyd: "Algorithm 97 (SHORTEST PATH)".
I<Communications of the ACM>, 5(6):345, B<1962>.

=item [3]

Stephan Warshall: "A theorem on boolean matrices."
I<Journal of the ACM>, 9(1):11-12, B<1962>.

=back

=head1 DEVELOPMENT
 
The current sources of this module are found on github,
L<< git://github.com/Abigail/test--regexp.git >>.

=head1 AUTHOR
    
Abigail L<< mailto:algorithm-graphs-transitiveclosure@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 1998, 2009 by Abigail

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

