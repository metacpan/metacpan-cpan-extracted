package Algorithm::Functional::BFS;

use common::sense;

use Carp;

=head1 NAME

Algorithm::Functional::BFS - A functional approach to the breadth-first
search algorithm.

This implementation supports both cyclic and acyclic graphs but does not
support edge or vertex weighting.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Algorithm::Functional::BFS;

    # Create your object.
    my $bfs = Algorithm::Functional::BFS->new
    (
        adjacent_nodes_func => $some_func,
        victory_func        => $some_other_func,
    );
    # Get a list (ref) of all the routes from your start node to the node(s)
    # that satisfy the victory condition.
    my $routes_ref = $bfs->search($start_node);

=head1 METHODS

=cut

=head2 new(%params)

Create a new Algorithm::Functional::BFS object with the specified parameters.

Required parameters:

    adjacent_nodes_func:
    A function (reference to a sub) that, given a node, returns an array ref
    of adjacent nodes.  If the node has no adjacent nodes, this function must
    return an empty array ref.

    victory_func:
    A function (referenec to a sub) that, given a node, returns a value that
    evaluates to true if and only if the node satisfies the victory condition
    of this search.

Optional parameters:

    include_start_node:
    If this is a true value, then the start node is a candidate for the
    victory condition.  That is, if the start node matches the victory
    condition, then a single route will be returned by the search algorithm,
    and that route will contain only the start node.

    one_result:
    If this is a true value, then the search stops after a single route is
    found, instead of searching for all the routes that satisfy the victory
    condition at the depth of the first route.

=cut
sub new
{
    my ($class, %opts) = @_;

    confess 'Missing "adjacent_nodes_func" parameter' unless
        $opts{adjacent_nodes_func};
    confess 'Missing "victory_func" parameter' unless $opts{victory_func};

    my %self =
    (
        adjacent_nodes_func => $opts{adjacent_nodes_func},
        victory_func        => $opts{victory_func},
        include_start_node  => $opts{include_start_node},
        one_result          => $opts{one_result},
    );

    bless(\%self, $class);
}

=head2 search($start_node)

    Perform a breadth-first-search from the specified node until the depth at
    which at least one node satisfies the victory condition.

    Returns an array ref of routes.  Each route is an array ref of the nodes
    that are along the route from the start node to the node at which the
    victory condition was satisfied.  Because this implementation works on
    cyclic graphs, multiple routes may be returned (and, indeed, multiple
    nodes at the same depth level may satisfy the victory condition).  If the
    "one_result" option was passed to the constructor, then only one route
    will be returned, but it will still be encapsulated in another array ref.

=cut
sub search
{
    my ($self, $start_node) = @_;

    confess 'Start node must be defined' unless $start_node;

    # Short circuit if the start node matches the victory condition.
    return [ [ $start_node ] ] if
        $self->{include_start_node} && $self->{victory_func}->($start_node);

    # Quick-to-read list of nodes we've already seen.
    my %seen = ( $start_node => 1 );

    # All the routes we've taken so far that are still valid.  This list
    # is used more-or-less like a queue.
    my @candidates = ( [ $start_node ] );

    # The final route list result.
    my @results;

    # Iterate until we have results or no candidates are left.
    until (@results > 0 || @candidates == 0)
    {
        # Keep new candidates separate from all candidates so that we can use
        # pop() in the while loop below.
        my @new_candidates;

        # Keep track of the nodes we've seen this loop that aren't already in
        # %seen.  By keeping these lists separate per iteration, we can find
        # multiple routes to the same target node.
        my %seen_this_loop;

        # Iterate over each of the candidate routes we have.
        while (my $candidate_ref = pop @candidates)
        {
            # Extract the most recent node from the current candidate.
            my $cur_node = $candidate_ref->[@$candidate_ref - 1];

            if (@$candidate_ref > 1 && $self->{victory_func}->($cur_node))
            {
                push(@results, $candidate_ref);
                last if $self->{one_result};
            }
            else
            {
                # Get the list of nodes adjacent to the current node.
                my $adj_ref = $self->{adjacent_nodes_func}->($cur_node);

                # For each node adjacent to the current node, if it hasn't
                # been seen before, add a route to it to the list of
                # candidates.
                while (my $adj_node = pop @$adj_ref)
                {
                    next if $seen{$adj_node};
                    $seen_this_loop{$adj_node} = 1;

                    my @new_route = ( @$candidate_ref, $adj_node );
                    push(@new_candidates, \@new_route);
                }
            }
        }

        @candidates = @new_candidates;
        %seen = ( %seen, %seen_this_loop );
    }

    return \@results;
}

=head1 AUTHOR

Colin Wetherbee, C<< <cww at cpan.org> >>

=head1 BUGS

Please file issues at this project's GitHub repository site.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Colin Wetherbee.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1;
