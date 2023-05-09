package Algorithm::Graphs::TransitiveClosure::Tiny;

use 5.010;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(floyd_warshall);

our $VERSION = '1.03';


sub floyd_warshall {
  my $graph    = shift;
  my $delEmpty = !shift;

  my @vertices = do {
    my %vertices;
    foreach my $v (keys(%$graph)) {
      if (%{$graph->{$v}}) {
        @vertices{$v, keys(%{$graph->{$v}})} = ();
      } elsif ($delEmpty) {
        delete $graph->{$v};
      }
    }
    keys %vertices;
  };
  foreach my $k (@vertices) {
    foreach my $i (@vertices) {
      foreach my $j (@vertices) {
        $graph->{$i}->{$j} = undef if (exists($graph->{$k}) && exists($graph->{$k}->{$j}) &&
                                       exists($graph->{$i}) && exists($graph->{$i}->{$k})
                                       && !exists($graph->{$i}->{$j}));
      }
    }
  }
  return $graph;
}



1; # End of Algorithm::Graphs::TransitiveClosure::Tiny




__END__


=head1 NAME

Algorithm::Graphs::TransitiveClosure::Tiny - Calculate the transitive closure.


=head1 VERSION

Version 1.03


=head1 SYNOPSIS

    use Algorithm::Graphs::TransitiveClosure::Tiny qw(floyd_warshall);

    # The hash values here need not to be undef, but floyd_warshall()
    # only adds undef.
    my $graph = {
                 0 => {0 => undef},
                 1 => {1 => undef, 2 => undef, 3 => undef},
                 2 => {1 => undef, 2 => undef},
                 3 => {0 => undef, 2 => undef, 3 => undef},
                };

    floyd_warshall $graph;

    print "There is a path from 2 to 0.\n" if
        exists($graph->{2}) && exists($graph->{2}->{0});

The latter can also be written shorter provided you accept autovivification:

    print "There is a path from 2 to 0.\n" if exists($graph->{2}->{0});



=head1 DESCRIPTION

This module provides a single function, C<floyd_warshall>, which is exported
on demand. It is an implementation of the well known I<Floyd-Warshall>
algorithm for computing the transitive closure of a graph.

The code is taken from L<Algorithm::Graphs::TransitiveClosure> but has been
modified. The difference is that this implementation of C<floyd_warshall()>:

=over

=item *

works on hashes only,

=item *

uses C<undef> for hash values, so an incidence must be checked with
C<exists()> (but for the input hash you are not forced to use C<undef>),

=item *

fixes following problem of L<Algorithm::Graphs::TransitiveClosure>:

Example:

   my $g = {
            0 => { 2 => 1},
            1 => { 0 => 1},
           };

There is an edge from 0 to 2 and an edge from 1 to 0. So the transitive
closure would contain an edge from 1 to 2. But calling C<floyd_warshall($g)>
from L<Algorithm::Graphs::TransitiveClosure> results in:

           {
            0 => { 2 => 1},
            1 => { 0 => 1},
           }

No change. The edge from 1 to 2 is missing (you would need to add C<2=E<gt>{}>
to C<$g> to get it right). But if you call C<floyd_warshall($g)> from
C<Algorithm::Graphs::TransitiveClosure::Tiny>, then the result is correct:

           {
            0 => { 2 => 1},
            1 => { 0 => 1,
                   2 => undef},
           }

Edge from 1 to 2 has been added! (Also note that it was possible to use 1
instead of C<undef> as hash value. This value is kept, but the value added by
the function is still C<undef>!)


=item *

By default, C<floyd_warshall($graph)> removes empty subhashes from C<$graph>,
e.g.

    my $graph = {
                 this => {that => undef},
                 that => {}
                };
    floyd_warshall($graph);

will result in

   {
    this => {that => undef}
   }

This behavior can be changed by setting optional second argument of
C<floyd_warshall> to a true value, i.e., calling C<floyd_warshall($graph, 1)>
with the above example hash will not remove C<that =E<gt> {}>.


=back

For convenience, C<floyd_warshall> returns C<$graph>.

For further information refer to L<Algorithm::Graphs::TransitiveClosure>.


=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-algorithm-graphs-transitiveclosure-tiny at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Graphs-TransitiveClosure-Tiny>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SEE ALSO

L<Algorithm::Graphs::TransitiveClosure>,
L<Text::Table::Read::RelationOn::Tiny>



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::Graphs::TransitiveClosure::Tiny


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-Graphs-TransitiveClosure-Tiny>

=item * Search CPAN

L<https://metacpan.org/release/Algorithm-Graphs-TransitiveClosure-Tiny>

=item * GitHub Repository

L<https://github.com/AAHAZRED/perl-Algorithm-Graphs-TransitiveClosure-Tiny.git>

=back



=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.




