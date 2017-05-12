use Test::More;
use Algorithm::ConstructDFA;
use Algorithm::ConstructDFA::XS;
use List::UtilsBy qw/sort_by partition_by/;
use List::MoreUtils qw/uniq/;
use Graph::Directed;
use Graph::RandomPath;
use strict;
use warnings;

my $tests = 0;

ok(++$tests);

for (1 .. 30) {
  my $g = Graph::Directed->random_graph(
    vertices   => int(rand(32)),
    edges_fill => 0.2
  );

  my %labels;
  my @vertices = $g->vertices;
  for my $v (@vertices) {
    next unless rand > 0.3;
    my $label = ['a', 'b', 'c']->[int rand 3];
    $g->set_vertex_attribute($v, 'label', $label);
  }
  
  my $start = [sort_by { scalar $g->successors($_) } @vertices]->[-1];
  
  next unless defined $start;
  
  my $final = [$g->all_successors($start), $start]
    ->[int rand(1 + scalar $g->all_successors($start))];
    
  next unless defined $final;
    
  my $dfa_xs = construct_dfa_xs(
    is_nullable  => sub {
      not $g->has_vertex_attribute($_[0], 'label')
    },
    is_accepting => sub { grep { $_ eq $final } @_ },
    successors   => sub { $g->successors($_[0]) },
    get_label    => sub { $g->get_vertex_attribute($_[0], 'label') // '' },
    start        => [ $start ],
  );

  my $dfa_pp = construct_dfa(
    is_nullable  => sub {
      not $g->has_vertex_attribute($_[0], 'label')
    },
    is_accepting => sub { grep { $_ eq $final } @_ },
    successors   => sub { $g->successors($_[0]) },
    get_label    => sub { $g->get_vertex_attribute($_[0], 'label') // '' },
    start        => [ $start ],
  );

#  use YAML::XS;
#  print Dump $dfa_xs;
  
  my %pp = partition_by { join ' ', sort @{ $_->{Combines} } } values %$dfa_pp;
  my %xs = partition_by { join ' ', sort @{ $_->{Combines} } } values %$dfa_xs;
#  print join "\n", sort keys %pp;
#  print "###\n";
#  print join "\n", sort keys %xs;
#  die;
}

done_testing($tests);



