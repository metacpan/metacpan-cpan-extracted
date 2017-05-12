package Algorithm::PageRank::XS;

use 5.008005;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Algorithm::PageRank::XS', $VERSION);

1;

__END__;

=head1 NAME

Algorithm::PageRank::XS - A Fast PageRank implementation

=head1 DESCRIPTION

This module implements a simple PageRank algorithm in C. The goal is
to quickly get a vector that is closed to the eigenvector of the
stochastic matrix of a graph.

L<Algorithm::PageRank> does some pagerank calculations, but it's 
slow and memory intensive. This module was developed to compute pagerank
on graphs with millions of arcs. This module will not, however, scale
up to quadrillions of arcs (see the TODO).

=head1 SYNOPSYS

    use Algorithm::PageRank::XS;

    my $pr = Algorithm::PageRank::XS->new();

    $pr->graph([
              'John'  => 'Joey',
              'John'  => 'James',
              'Joey'  => 'John',
              'James' => 'Joey',
              ]
              );

    $pr->result();
    # {
    #      'James' => '0.569840431213379',
    #      'Joey'  => '1',
    #      'John'  => '0.754877686500549'
    # }



    #
    #
    # The following simple program takes up arcs and prints the ranks.
    use Algorithm::PageRank::XS;

    my $pr = Algorithm::PageRank::XS->new();

    while (<>) {
        chomp;
        my ($from, to) = split(/\t/, $_);
        $pr->add_arc($from, $to);
    }

    my $r = $pr->results();
    while (my ($name, $rank) = each(%{$r})) {
        print "$name,$rank\n";
    }

=head1 METHODS

=head2 new %PARAMS

Create a new PageRank object. Possible parameters:

=over 4

=item alpha

This is (1 - how much people can move from one node to another unconnected one randomly). Decreasing
this number makes convergence more likely, but brings us further from the true eigenvector.

=item max_tries

The maximum number of tries until we give up trying to achieve convergence.

=item convergence

The maximum number the difference between two subsequent vectors must be before we say we are
"convergent enough". The convergence rate is the rate at which C<alpha^t> goes to 0. Thus,
if you set C<alpha> to C<0.85>, and C<convergence> to C<0.000001>, then you will need C<85> tries.

=back

=head2 add_arc

Add an arc to the pagerank object before running the computation.
The actual values don't matter. So you can run:

    $pr->add_arc("Apple", "Orange");

and you mean that C<"Apple"> links to C<"Orange">.


=head2 graph

Add a graph, which is just an array of from, to combinations.
This is equivalent to calling C<add_arc> a bunch of times, but may
be more convenient.

=head2 from_file FILE

This will load arcs from a file, whose lines contain:

    from,to\n

It's designed to be fast, and doesn't handle quoting or even commas
in the from string. This will just allow you to load a bit faster and maybe
save a few megabytes of ram if you wanted to.

=head2 iterate

Doesn't do anything, but provided so that you can substitute this module
in for L<Algorithm::PageRank>.

=head2 result

Compute the pagerank vector, and return it as a hash.

Whatever you called the nodes when specifying the arcs will be the keys of this hash, where the
values will be the vector.

The result vector is normalized such that the sum is C<1> (the L-1 norm). You can normalize it any other way you like if you don't like this.

=head1 BUGS

None known.

=head1 TODO

=over 4

=item * Support for "Personalized PageRank" (see L<http://ilpubs.stanford.edu:8090/596/>)

=item * We may want to support C<double> values rather than single floats

=item * We may or may not want to adjust the weighting of individual arcs, as you cannot do now.

=item * At present the indexes are C<unsigned int>, rather than C<size_t>. Thus this will not scale with 64-bit architectures.

=item * It'd be nice to be able to use C<mmap(2)> to efficiently use the hard drive to scale to places where memory can't take us.

=back

=head1 SPEED

This module is pretty fast. I ran this on a 1 million node set with 4.5 million arcs in 57 seconds on my 32-bit 1.8GHz laptop. Let me know if you have any performance tips. 

Below are the tables for the current iteration in trials per second and arcs per second. Keep in mind that for some of these there are large numbers of arcs (C<.2%> load with C<100,000> nodes means C<20,000,000> arcs!

    +-----------------+-----------------+-----------------+---------------+---------------+
    | test            | XS trials / sec | PL trials / sec | XS arcs / sec | PL arcs / sec |
    +-----------------+-----------------+-----------------+---------------+---------------+
    | 10 nodes @50%   | 4533.207        | 53.741          | 6890.474      | 81.687        | 
    | 10 nodes @100%  | 3822.595        | 46.084          | 13761.342     | 165.901       | 
    | 1000 @10%       | 4.542           | 0.120           | 18109.287     | 2390.898      | 
    | 1000 @50%       | 1.055           | 0.031           | 21082.599     | 15720.595     | 
    | 1000 @100%      | 0.562           | 0.016           | 56121.722     | 16301.088     | 
    | 100000 @.0001%* | 1.348           |                 | 141855.819    |               | 
    | 100000 @.01%*   | 0.217           |                 | 23174.341     |               | 
    | 100000 @.1%*    | 0.034           |                 | 344796.415    |               | 
    | 100000 @.2%*    | 0.017           |                 | 348070.697    |               | 
    +-----------------+-----------------+-----------------+---------------+---------------+

* For some of these tests I cheated a little bit and used from_file() since there were so many arcs.


=head1 SEE ALSO

L<Algorithm::PageRank>

=head1 AUTHOR

Michael Axiak <mike@axiak.net>

=head1 COPYRIGHT

Copyright (C) 2008 by Michael Axiak <mike@axiak.net>

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself

=cut
