use strict;
use warnings;
use 5.024000;

use Test::More;
use Algorithm::ConstructDFA2;
use List::Util qw/all any/;
use List::UtilsBy qw/sort_by/;
use List::MoreUtils qw/uniq indexes/;
use Graph::Directed;
use Graph::Feather;
use YAML::XS;

my @alphabet = ( 11111, 22222, 33333, 44444, 55555, 66666 );
my $max_vertices = 8;
my $nullable_odds = 0.3;
my $matches_odds = 1 / @alphabet;

sub get_dfa {
  my ($g, $start, $final, $nullable, $matches) = @_;

  my $db_file = ':memory:';
#  unlink $db_file;

  my $dfa = Algorithm::ConstructDFA2->new(
    input_alphabet     => [ @alphabet ],
    input_vertices     => [ $g->vertices ],
    input_edges        => [ $g->edges ],

    vertex_nullable    => sub {
      return $nullable->{ $_[0] };
    },

    vertex_matches     => sub {
      return $matches->{ $_[0] }{ $_[1] };
    },

    storage_dsn        => "dbi:SQLite:dbname=$db_file",
  );

  my $start_id = $dfa->find_or_create_state_id( $start );

  while (1) {
    my $max = 1 + int rand 100;
    my $count = $dfa->compute_some_transitions($max);
    ok $count <= $max, "obeys transition count limit"
      or diag(" $count vs $max ");
    last unless $count;
  }

  return $dfa, $start_id;
}

sub random_element {
  return unless @_;
  [@_]->[ int rand scalar @_ ]
}

sub random_graph {
  my $g = Graph::Directed->random_graph(
    vertices => $max_vertices,
  );

  # workaround for bug in Graph::Directed
  $g->delete_vertex( 0 );

  return Graph::Feather->new(
    vertices => [ $g->vertices ],
    edges => [ $g->edges ],
  )
}

sub random_path_between {
  my ($g, $start, $final, $max_length) = @_;

  my $dbh = $g->{dbh};

  return unless grep {
    $_ eq $final
  } $start, $g->all_successors($start);

  $max_length //= 1_000;

  my $sth = $dbh->prepare(q{
    WITH RECURSIVE random_path(pos, vertex) AS (
      SELECT 0 AS pos, ? AS vertex
      UNION ALL
      SELECT
        random_path.pos + 1 AS pos,
        (SELECT Edge.dst
        FROM Edge
        WHERE Edge.src = random_path.vertex
        ORDER BY RANDOM()
        LIMIT 1) AS next
      FROM random_path
      WHERE next IS NOT NULL
    )
    SELECT vertex
    FROM random_path
    LIMIT ?
  });

  while (1) {

    my @path = map { @$_ } $dbh->selectall_array($sth,
      {}, $start, $max_length);

    my @endpoints = indexes { $_ eq $final } @path;
    my $last_elem = random_element( @endpoints );

    next unless defined $last_elem;

    splice @path, $last_elem + 1;

    return @path;
  }
}

sub random_dfa_path {
  my ($dfa, $start_id, $max_length, @accepting) = @_;

  my $dbh = $dfa->_dbh;

#  return unless grep {
#    $_ eq $final
#  } $start, $g->all_successors($start);

  $max_length //= 1_000;

  my $sth = $dbh->prepare(q{
    WITH RECURSIVE random_dfa_path(pos, state) AS (
      SELECT 0 AS pos, ? AS state
      UNION ALL
      SELECT
        random_dfa_path.pos + 1 AS pos,
        (SELECT Transition.dst
        FROM Transition
        WHERE Transition.src = random_dfa_path.state
        ORDER BY RANDOM()
        LIMIT 1) AS next
      FROM random_dfa_path
      WHERE next IS NOT NULL
    )
    SELECT state
    FROM random_dfa_path
    LIMIT ?
  });

  my %accepting = map { $_ => 1 } @accepting;

  while (1) {

    my @path = map { @$_ } $dbh->selectall_array($sth,
      {}, $start_id, $max_length);

    my @endpoints = indexes { %accepting{$_} } @path;
    my $last_elem = random_element( @endpoints );

    next unless defined $last_elem;

    splice @path, $last_elem + 1;

    return @path;
  }
}

sub inputs_from_vertex_path {
  my ($matches, $nullable, @path) = @_;

  my @inputs = map {
    my $v = $_;

    my @options = grep {
      $matches->{$v}{$_}
    } keys %{ $matches->{$v} };

    random_element( @options );

  } grep {
    not $nullable->{$_}
  } @path[ 0 .. $#path - 1 ];

  return @inputs;  
}

sub path_to_vertex_pos_pairs {
  my ($nullable, @path) = @_;

  my $i = 0;

  return map { $nullable->{$_} ? [$i, $_] : [$i++, $_] } @path;
}

sub simulate_dfa_on_input {
  my ($dfa, $start_id, @inputs) = @_;

  $dfa->_dbh->begin_work();

  $dfa->_dbh->do(q{
    CREATE TEMPORARY TABLE temp_test_input(value);
  });

  my $sth = $dfa->_dbh->prepare(q{
    INSERT INTO temp_test_input(value) VALUES(?)
  });

  $sth->execute($_) for @inputs;

  my @dfa_trail = $dfa->_dbh->selectall_array(q{
    WITH RECURSIVE dfa_trail(pos, src, input, dst) AS (

        SELECT p.rowid AS pos, t.src, t.input, t.dst
        FROM temp_test_input p
          LEFT JOIN Transition t
            ON (t.input = p.value)
        WHERE t.src = ? AND p.rowid = 1

      UNION ALL

        SELECT p.rowid AS pos, t.src, t.input, t.dst
        FROM dfa_trail d
          LEFT JOIN temp_test_input p 
            ON (p.rowid = d.pos + 1)
          LEFT JOIN Transition t
            ON (t.src = d.dst AND t.input = p.value)
        WHERE p.value IS NOT NULL
    )
    SELECT * FROM dfa_trail
  }, {}, $start_id);

  # NOTE: @dfa_trail is empty if no input

  $dfa->_dbh->rollback;

  return @dfa_trail;
}

sub dfa_path_join_5tuple {
  my ($dfa, @dfa_path) = @_;

  $dfa->_dbh->begin_work();

  $dfa->_dbh->do(q{
    CREATE TEMPORARY TABLE temp_dfa_path(state)
  });

  my $sth = $dfa->_dbh->prepare(q{
    INSERT INTO temp_dfa_path(state) VALUES(?)
  });

  $sth->execute($_) for @dfa_path;

  my @result = $dfa->_dbh->selectall_array(q{
    SELECT
      p1.rowid AS src_pos,
      v.src_state, v.src_vertex,
      v.via,
      IFNULL(p2.rowid, p1.rowid) AS dst_pos,
      v.dst_state, v.dst_vertex
    FROM
      temp_dfa_path p1
        LEFT JOIN temp_dfa_path p2
          ON (p1.rowid + 1 = p2.rowid)
        LEFT JOIN view_transitions_as_5tuples v
          ON (v.src_state = p1.state AND
            (v.dst_state = p2.state
               OR (v.via IS NULL AND v.dst_state = v.src_state)))
    WHERE v.dst_state IS NOT NULL
  });

  $dfa->_dbh->rollback();

  return @result;
}

for ( 1 .. 100 ) {
  my $g = random_graph();
  my $start = random_element( $g->vertices );
  my $final = random_element($start, $g->all_successors($start));

  my %nullable;
  $nullable{ $_ } = rand() < $nullable_odds for $g->vertices;

  my %matches;
  for my $v ($g->vertices) {
    next if $nullable{$v};
    for my $ch (@alphabet) {
      $matches{$v}{$ch} = rand() < $matches_odds;
    }
    $matches{$v}{random_element( @alphabet )} = 1;
  }

  my ($dfa, $start_id) = get_dfa($g, $start, $final,
    \%nullable, \%matches);

  my @accepting = $dfa->cleanup_dead_states(sub {
    scalar grep { $_ eq $final } @_;
  });

  my %accepting_id = map { $_ => 1 } @accepting;

  ok scalar(@accepting), 'at least 1 accepting state';

  my $dead_state_id = $dfa->dead_state_id;

  for my $dfa_path_counter ( 1 .. 16 ) {
    my @dfa_path = random_dfa_path($dfa, $start_id, 100, @accepting);

    next unless @dfa_path > 1;

    my @xxx = dfa_path_join_5tuple($dfa, @dfa_path);

    ok((any {
    my ($dst_pos, $dst_state, $dst_vertex) = @{$_}[4,5,6];
      1
      and $dst_pos == @dfa_path
      and $dst_vertex eq $final
      and grep { $_ eq $dst_state } @accepting
    } @xxx), "joined 5tuples contain final");

    ok((all { $g->has_edge($_->[2], $_->[6] ) } @xxx),
      "random dfa path corresponds to original graph over 5tuples");
  }

  my %all_transitions = map {
    join(" ", @$_) => 1
  } $dfa->transitions_as_3tuples;

  for my $path_counter ( 1 .. 16 ) {

    my @path = random_path_between($g, $start, $final, 32);

    ok @path > 0, "found random path in graph";
    is $path[0], $start, "random path begins with start vertex";
    is $path[-1], $final, "random paths ends with final vertex";

    my @inputs = inputs_from_vertex_path(\%matches,
      \%nullable, @path);

    my @dfa_trail = simulate_dfa_on_input($dfa, $start_id, @inputs);

    my $last_state = @dfa_trail ? $dfa_trail[-1][3] : $start_id;
    my $last_accepts = grep { $_ eq $last_state } @accepting;

    ok $last_accepts, "DFA accepts random path $path_counter";

    my %trail_transitions = map {
      join(" ", @{$_}[1,2,3]) => 1
    } @dfa_trail;

    ok((all { exists $all_transitions{$_} } keys %trail_transitions),
      "proper computation of trail transitions and all transitions");

    my @dfa_path = ($start_id, map { $_->[3] } @dfa_trail);

    my %dfa_vertices = do {
      my $i = 0;
      map {
        $i++;
        map { join(" ", ($i - 1, $_)), 1 } $dfa->vertices_in_state($_)
      } @dfa_path;
    };

    my %vpp = map { join(" ", @$_), 1 }
      path_to_vertex_pos_pairs(\%nullable, @path);

    ok((all { exists $dfa_vertices{$_} } keys %vpp),
      "vertex path corresponds to dfa trail plus vertices");
  }

}

done_testing();

__END__
