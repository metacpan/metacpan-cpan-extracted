package Algorithm::Graphs::Reachable::Tiny;

use 5.008;
use strict;
use warnings;

use Carp;
use Exporter 'import';

our $VERSION = '0.10';

our @EXPORT_OK = qw(all_reachable);


sub all_reachable {
  @_ == 2 or croak("Need exactly two arguments!");
  my ($graph, $nodes) = @_;
  my %visited = ref($nodes) eq "ARRAY" ? map {$_ => undef} @{$nodes} : %{$nodes};
  return {} unless %visited;
  my @queue = keys(%visited);
  if (ref($graph) eq 'HASH') {
  return \%visited unless %{$graph};
    while (defined(my $v = shift(@queue))) {
      if (exists($graph->{$v})) { ## we need this if() to avoid autovivification!
        foreach my $s (keys(%{$graph->{$v}})) {
          if (!exists($visited{$s})) {
            $visited{$s} = undef;
            push(@queue, $s);
          }
        }
      }
    }
  }
  elsif (ref($graph) eq 'ARRAY') {
  return \%visited unless @{$graph};
    while (defined(my $v = shift(@queue))) {
      if (defined($graph->[$v])) {
        foreach my $s (keys(%{$graph->[$v]})) {
          if (!exists($visited{$s})) {
            $visited{$s} = undef;
            push(@queue, $s);
          }
        }
      }
    }
  } else {
    croak("Arg 1 must be an ARRAY or HASH reference");
  }
  return \%visited;
}




1; # End of Algorithm::Graphs::Reachable::Tiny


__END__


=pod


=head1 NAME

Algorithm::Graphs::Reachable::Tiny - Calculate the reachable nodes in a graph.

=head1 VERSION

Version 0.10


=head1 SYNOPSIS

   use Algorithm::Graphs::Reachable::Tiny qw(all_reachable);

   my %g = (
            0 => {1 => undef},
            1 => {2 => undef, 4 => undef},
            2 => {3 => undef},
            4 => {5 => undef},
            6 => {7 => undef},
            7 => {8 => undef},
            8 => {9 => undef},
            9 => {7 => undef, 10 => undef}
           );

   my $reachable = all_reachable(\%g, [4, 7]);

or

   my $reachable = all_reachable(\%g, {4 => undef, 7 => undef});

or

  my @g = (
           {1 => undef},
           {2 => undef, 4 => undef},
           {3 => undef},
           {},
           {5 => undef},
           undef,
           {7 => undef},
           {8 => undef},
           {9 => undef},
           {7 => undef, 10 => undef}
          );

   my $reachable = all_reachable(\@g, [4, 7]);


=head1 DESCRIPTION

Provides a function to determine all nodes reachable from a set of nodes in a
graph.

A graph must be represented like this:

    my $graph = {
                 this => {that => undef,
                          # ...

                         },
                 # ...
                };

In this example, there is an edge from 'this' to 'that'. Note that you are not
forced to use C<undef> as hash value.

If your vertices are integers, you can also specify the graph as an array of
hashes. Non-existent or unconnected vertices can be specified by an empty hash
or by C<undef>.

=head2 FUNCTIONS

=head3 all_reachable(GRAPH, NODES)

I<C<GRAPH>> must be a reference to a hash of hashes or to an array of
hashes. It represents the graph as described above.  I<C<NODES>> must be a
reference to a hash or an array.

The function determines the set of all nodes in I<C<GRAPH>> that are reachable
from one of the nodes in I<C<NODES>>. It returns a reference to a hash
that represents this set.

=over

=item *

If I<C<NODES>> is empty, then the function returns an empty set.

=item *

If I<C<GRAPH>> is empty, then the returned set contains exactly the nodes in
I<C<NODES>>.

=item *

If I<C<NODES>> contains elements that are not in I<C<GRAPH>>, then those
elements are still in the result set.

Note: If I<C<GRAPH>> is an array reference value, then I<C<NODES>> may only
contain integers.

=back

Example:

   my %g = (
            0 => {1 => undef},
            1 => {2 => undef, 4 => undef},
            2 => {3 => undef},
            4 => {5 => undef},
            6 => {7 => undef},
            7 => {8 => undef},
            8 => {9 => undef},
            9 => {7 => undef, 10 => undef}
           );

   my $reachable = all_reachable(\%g, {4 => undef, 7 => undef});

C<$reachable> containes:

          {
            4  => undef,
            5  => undef,
            7  => undef,
            8  => undef,
            9  => undef,
            10 => undef,
          }

The following call would lead to the same result:

   my $reachable = all_reachable(\%g, [4, 7]);


=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-algorithm-graphs-reachable-tiny at rt.cpan.org>, or through the web
interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Graphs-Reachable-Tiny>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::Graphs::Reachable::Tiny


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-Graphs-Reachable-Tiny>

=item * Search CPAN

L<https://metacpan.org/release/Algorithm-Graphs-Reachable-Tiny>

=item * GitHub Repository

L<https://github.com/AAHAZRED/perl-Algorithm-Graphs-Reachable-Tiny>

=back



=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 SEE ALSO

L<Algorithm::Graphs::TransitiveClosure::Tiny>,
L<Graph>,
L<Text::Table::Read::RelationOn::Tiny>

=cut
