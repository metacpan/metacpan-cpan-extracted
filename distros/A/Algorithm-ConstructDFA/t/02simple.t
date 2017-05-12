use Test::More;
use Algorithm::ConstructDFA;
use List::UtilsBy qw/sort_by/;
use List::MoreUtils qw/uniq/;
use Graph::Directed;
use Graph::RandomPath;

my $tests = 0;

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
    
  my $dfa = construct_dfa(
    is_nullable  => sub {
      not $g->has_vertex_attribute($_[0], 'label')
    },
#    is_accepting => sub { grep { $_ eq $final } @_ },
    final => [ $final ],
    successors   => sub { $g->successors($_[0]) },
    get_label    => sub { $g->get_vertex_attribute($_[0], 'label') // '' },
    start        => [ $start ],
  );
  
  my $dfa_g = Graph::Directed->new;
  my $dfa_g_final = "final";
  for my $s (keys %$dfa) {
    for my $label (keys %{$dfa->{$s}{NextOver}}) {
      my $mid = $s . ':' . $label;
      $dfa_g->add_edge($s, $mid);
      $dfa_g->add_edge($mid, $dfa->{$s}{NextOver}{$label});
      $dfa_g->set_vertex_attribute($mid, 'label', $label) if length $label;
      $dfa_g->add_edge($s, $dfa_g_final)
        if $dfa->{$s}{Accepts};
      $dfa_g->add_edge($dfa->{$s}{NextOver}{$label}, $dfa_g_final)
        if $dfa->{$dfa->{$s}{NextOver}{$label}}{Accepts};
    }
  }

  my $make_random_path_enumerator = sub {
    return Graph::RandomPath->create_generator(@_);
    my ($graph, $src, $dst) = @_;
    my %to_src = map { $_ => 1 } $src, $graph->all_successors($src);
    my %to_dst = map { $_ => 1 } $dst, $graph->all_predecessors($dst);
    my $copy = Graph::Directed->new(edges => [ grep {
      $to_src{$_->[0]} and $to_src{$_->[1]} and
      $to_dst{$_->[0]} and $to_dst{$_->[1]}
    } $graph->edges]);

    return sub {
      my @path = ($src);
      for (1 .. int(rand(100))) {
        my $s = $copy->random_successor($path[-1]);
        last unless defined $s;
        push @path, $s;
      }
      unless ($path[-1] eq $dst) {
        splice @path, $#path, 1, $copy->SP_Dijkstra($path[-1], $dst);
      }
      return @path;
    }
  };

  for my $config ([$g, $start, $final, $dfa_g, 1, $dfa_g_final],
                  [$dfa_g, 1, $dfa_g_final, $g, $start, $final]
                  ) {

    my ($g1, $start, $final, $g2, $start2, $final2) = @$config;

    my $rnd;
    eval {
      $rnd = Graph::RandomPath->create_generator($g1, $start, $final);
    };
    next if $@;

    for (1 .. 4) {
      my @path =  $rnd->();
      
      my @word =
        map { $g1->get_vertex_attribute($_, 'label') } 
        grep { $g1->has_vertex_attribute($_, 'label') }
        @path[0 .. $#path - 1];

#      use YAML::XS;
#      warn Dump { path => \@path, word => join('/', @word),  };
        
      my @word_copy = @word;

      my @state = $start2;

      while (1) {
        my %seen;
        my @todo = @state;
        @state = ();
        while (@todo) {
          my $t = pop @todo;
          next if $seen{$t}++;
          push @state, $t;
          next if $g2->has_vertex_attribute($t, 'label');
          push @todo, $g2->successors($t);
        }
 #       warn "in @state";
        last unless @word;
        my $c = shift @word;
        @state = uniq map {
          $g2->successors($_)
        } grep {
          $g2->has_vertex_attribute($_, 'label') and
          $g2->get_vertex_attribute($_, 'label') eq $c;
        } @state;
#        warn "out @state";
      }
      
      my $matches = grep { $_ eq $final2 } @state;
      $matches ||= 1 if not @word_copy;
      
      ok($matches);
      $tests++;
      
      next;
    }
  }
  
}

done_testing($tests);



