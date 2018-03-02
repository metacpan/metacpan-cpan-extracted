package Algorithm::ConstructDFA2;
use strict;
use warnings;
use 5.024000;
use Types::Standard qw/:all/;
use List::UtilsBy qw/sort_by nsort_by partition_by/;
use List::MoreUtils qw/uniq/;
use Moo;
use Memoize;
use Log::Any qw//;
use DBI;

our $VERSION = '0.04';

has 'input_alphabet' => (
  is       => 'ro',
  required => 1,
  isa      => ArrayRef[Int],
);

has 'input_vertices' => (
  is       => 'ro',
  required => 1,
  isa      => ArrayRef[Int],
  default  => sub { [] },
);

has 'input_edges' => (
  is       => 'ro',
  required => 1,
  isa      => ArrayRef[ArrayRef[Int]],
);

has 'vertex_matches' => (
  is       => 'ro',
  required => 1,
  isa      => CodeRef,
);

has 'vertex_nullable' => (
  is       => 'ro',
  required => 1,
  isa      => CodeRef,
);

has 'storage_dsn' => (
  is       => 'ro',
  required => 1,
  isa      => Str,
  default  => sub {
    'dbi:SQLite:dbname=:memory:'
  },
);

has '_dbh' => (
  is       => 'ro',
  required => 0,
  writer   => '_set_dbh',
);

has 'dead_state_id' => (
  is       => 'ro',
  required => 0,
  isa      => Int,
  writer   => '_set_dead_state_id',
);

has '_log' => (
  is       => 'rw',
  required => 0,
  default  => sub {
    Log::Any->get_logger()
  },
);

sub BUILD {
  my ($self) = @_;

  ###################################################################
  # Create dbh

  $self->_log->debug("Creating database");

  my $dbh = DBI->connect( $self->storage_dsn );
  $dbh->{RaiseError} = 1;
#  $dbh->{AutoCommit} = 1;

  $self->_set_dbh( $dbh );

  ###################################################################
  # Register Extension functions

  $self->_log->debug("Register extension functions");

  $self->_dbh->sqlite_create_function( '_vertex_matches', 2, sub {
    return !! $self->vertex_matches->(@_);
  });

  $self->_dbh->sqlite_create_function( '_vertex_nullable', 1, sub {
    return !! $self->vertex_nullable->(@_);
  });

  $self->_dbh->sqlite_create_function( '_canonical', 1, sub {

    return "" unless defined $_[0];

    # Since SQLite's GROUP_CONCAT does not guarantee ordering,
    # we sort the items in the list ourselves here.
    my @vertices = sort { $a <=> $b }
      uniq _vertex_str_to_vertices(@_);

    return _vertex_str_from_vertices(@vertices);
  });

  ###################################################################
  # Deploy schema

  $self->_log->debug("Deploying schema");
  $self->_deploy_schema();

  ###################################################################
  # Insert input data

  $self->_log->debug("Initialising input");
  $self->_init_input;

  $self->_log->debug("Initialising vertices");
  $self->_init_vertices;

  $self->_log->debug("Initialising edges");
  $self->_init_edges;

  ###################################################################
  # Insert pre-computed data

  $self->_log->debug("Initialising match data");
  $self->_init_matches;

  $self->_log->debug("Computing epsilon closures");
  $self->_init_epsilon_closure;

  ###################################################################
  # Let DB analyze data so far

  $self->_log->debug("Updating DB statistics");
  $self->_dbh->do('ANALYZE');

  # FIXME: strictly speaking, the dead state is a ombination of all
  # vertices from which an accepting combination of vertices cannot
  # be reached. That might be important. Perhaps when later merging
  # dead states, this would be resolved automatically? Probably not.

  my $dead_state_id = $self->find_or_create_state_id();
  $self->_set_dead_state_id($dead_state_id);
}

sub _deploy_schema {
  my ($self) = @_;
  
  local $self->_dbh->{sqlite_allow_multiple_statements} = 1;

  $self->_dbh->do(q{
    -----------------------------------------------------------------
    -- Pragmata
    -----------------------------------------------------------------

    PRAGMA foreign_keys = ON;
    PRAGMA synchronous = OFF;
    PRAGMA journal_mode = OFF;
    PRAGMA locking_mode = EXCLUSIVE;
    
    -----------------------------------------------------------------
    -- Input Alphabet
    -----------------------------------------------------------------

    CREATE TABLE Input (
      value INTEGER PRIMARY KEY NOT NULL
    );

    -----------------------------------------------------------------
    -- Input Graph Vertex
    -----------------------------------------------------------------

    CREATE TABLE Vertex (
      value INTEGER PRIMARY KEY
        CHECK(printf("%u", value) = value),
      is_nullable BOOL
    );

    CREATE TRIGGER trigger_Vertex_insert
      AFTER INSERT ON Vertex
      BEGIN

        UPDATE Vertex
        SET is_nullable = _vertex_nullable(NEW.value)
        WHERE value = NEW.value;

      END;

    -----------------------------------------------------------------
    -- Input Graph Edges
    -----------------------------------------------------------------

    CREATE TABLE Edge (
      src INTEGER NOT NULL,
      dst INTEGER NOT NULL,
      UNIQUE(src, dst),
      FOREIGN KEY (dst)
        REFERENCES Vertex(value)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
      FOREIGN KEY (src)
        REFERENCES Vertex(value)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
    );

    CREATE INDEX Edge_idx_dst ON Edge (dst);

    -- can use covering index instead
    -- CREATE INDEX Edge_idx_src ON Edge (src);

    CREATE TRIGGER trigger_Edge_insert
      BEFORE INSERT ON Edge
      BEGIN
        INSERT OR IGNORE
        INTO Vertex(value)
        VALUES(NEW.src);

        INSERT OR IGNORE
        INTO Vertex(value)
        VALUES(NEW.dst);
      END;

    -----------------------------------------------------------------
    -- Epsilon Closure
    -----------------------------------------------------------------

    CREATE TABLE Closure (
      root INTEGER NOT NULL,
      e_reachable INTEGER NOT NULL,
      UNIQUE(root, e_reachable),
      FOREIGN KEY (root)
        REFERENCES Vertex(value)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
      FOREIGN KEY (e_reachable)
        REFERENCES Vertex(value)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
    );

    CREATE INDEX Closure_idx_dst ON Closure(e_reachable);

    -- can use covering index instead
    -- CREATE INDEX Closure_idx_src ON Closure(root);

    -----------------------------------------------------------------
    -- DFA States
    -----------------------------------------------------------------

    CREATE TABLE State (
      state_id INTEGER PRIMARY KEY NOT NULL,
      vertex_str TEXT UNIQUE NOT NULL
    );

    -----------------------------------------------------------------
    -- DFA State Composition
    -----------------------------------------------------------------

    CREATE TABLE Configuration (
      state INTEGER NOT NULL,
      vertex INTEGER NOT NULL,
      UNIQUE(state, vertex),
      FOREIGN KEY (state)
        REFERENCES State(state_id)
        ON DELETE CASCADE
        ON UPDATE NO ACTION,
      FOREIGN KEY (vertex)
        REFERENCES Vertex(value)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
    );

    CREATE INDEX Configuration_idx_vertex ON Configuration (vertex);

    -- can use covering index instead
    -- CREATE INDEX Configuration_idx_state ON Configuration (state);

    -----------------------------------------------------------------
    -- Input Graph Vertex Match data
    -----------------------------------------------------------------

    CREATE TABLE Match (
      vertex INTEGER NOT NULL,
      input INTEGER NOT NULL,
      UNIQUE(vertex, input),
      FOREIGN KEY (input)
        REFERENCES Input(value)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
      FOREIGN KEY (vertex)
        REFERENCES Vertex(value)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
    );

    CREATE INDEX Match_idx_input ON Match (input);

    -- can use covering index instead
    -- CREATE INDEX Match_idx_vertex ON Match (vertex);

    -----------------------------------------------------------------
    -- DFA Transitions
    -----------------------------------------------------------------

    CREATE TABLE Transition (
      src INTEGER NOT NULL,
      input INTEGER NOT NULL,
      dst INTEGER NOT NULL,
      UNIQUE(src, input),
      FOREIGN KEY (dst)
        REFERENCES State(state_id)
        ON DELETE CASCADE
        ON UPDATE NO ACTION,
      FOREIGN KEY (input)
        REFERENCES Input(value)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
      FOREIGN KEY (src)
        REFERENCES State(state_id)
        ON DELETE CASCADE
        ON UPDATE NO ACTION
    );

    CREATE INDEX Transition_idx_dst ON Transition (dst);
    CREATE INDEX Transition_idx_input ON Transition (input);

    -- can use covering index instead
    -- CREATE INDEX Transition_idx_src ON Transition (src);

    -----------------------------------------------------------------
    -- Views
    -----------------------------------------------------------------

    CREATE VIEW view_transitions_as_5tuples AS 
      ---------------------------------------------------------------
      -- epsilon transitions
      ---------------------------------------------------------------
      SELECT
        s.state_id AS src_state,
        e.src AS src_vertex,
        NULL AS via,
        s.state_id AS dst_state,
        e.dst AS dst_vertex
      FROM
        State s
        INNER JOIN Configuration c1 ON (c1.state = s.state_id)
        INNER JOIN Configuration c2 ON (c2.state = s.state_id)
        INNER JOIN Edge e
          ON (e.src = c1.vertex AND e.dst = c2.vertex)
        INNER JOIN Vertex v
          ON (v.value = e.src AND v.is_nullable = 1)

    UNION ALL

      ---------------------------------------------------------------
      -- transitions over terminals
      ---------------------------------------------------------------
      SELECT
        tr.src AS src_state,
        e.src AS src_vertex,
        tr.input AS via,
        tr.dst AS dst_state,
        e.dst AS dst_vertex
      FROM
        Transition tr
        INNER JOIN Configuration c1 ON (c1.state = tr.src)
        INNER JOIN Configuration c2 ON (c2.state = tr.dst)
        INNER JOIN Edge e
          ON (e.src = c1.vertex AND e.dst = c2.vertex)
        INNER JOIN Match m
          ON (m.input = tr.input AND m.vertex = c1.vertex);
    
    CREATE VIEW view_transitions_as_configuration_pair AS
    SELECT
      c1.rowid AS src_id,
      c2.rowid AS dst_id
    FROM
      view_transitions_as_5tuples t
        INNER JOIN Configuration c1
          ON (c1.state = t.src_state
            AND c1.vertex = t.src_vertex)
        INNER JOIN Configuration c2
          ON (c2.state = t.dst_state
            AND c2.vertex = t.dst_vertex);
  });
}

sub _insert_or_ignore {
  my ($self, $table, $values, @cols) = @_;

  my $cols_str = join ", ",
    map { $self->_dbh->quote_identifier($_) } @cols;

  my $placeholders_str = join ", ",
    map { '?' } @cols;

  my $table_str = $self->_dbh->quote_identifier($table);

  my $sth = $self->_dbh->prepare(sprintf q{
    INSERT OR IGNORE INTO %s(%s) VALUES (%s)
  }, $table_str, $cols_str, $placeholders_str);

  $self->_dbh->begin_work();
  $sth->execute(ref($_) eq 'ARRAY' ? @$_ : $_) for @$values;
  $self->_dbh->commit();
}

sub _init_input {
  my ($self) = @_;
  _insert_or_ignore($self, 'Input', $self->input_alphabet, 'value');
}

sub _init_vertices {
  my ($self) = @_;
  _insert_or_ignore($self, 'Vertex', $self->input_vertices, 'value');
}

sub _init_edges {
  my ($self) = @_;
  _insert_or_ignore($self, 'Edge', $self->input_edges, 'src', 'dst');
}

sub _init_matches {
  my ($self) = @_;

  $self->_dbh->do(q{
    INSERT INTO Match(vertex, input)
    SELECT Vertex.value, Input.value
    FROM
      Vertex CROSS JOIN Input
    WHERE
      _vertex_matches(Vertex.value, Input.value)+0 = 1
    ORDER BY Vertex.value, Input.value
  });
}

sub _init_epsilon_closure {
  my ($self) = @_;

  $self->_dbh->do(q{
    INSERT INTO Closure(root, e_reachable)
    WITH RECURSIVE all_e_successors_and_self(root, v) AS (

      SELECT value AS root, value AS v FROM vertex

      UNION

      SELECT r.root, Edge.dst      
      FROM Edge
        INNER JOIN all_e_successors_and_self AS r
          ON (Edge.src = r.v)
        INNER JOIN Vertex AS src_vertex
          ON (Edge.src = src_vertex.value)
      WHERE src_vertex.is_nullable
    )
    SELECT root, v FROM all_e_successors_and_self
    ORDER BY root, v
  });
}

sub _vertex_str_from_vertices {
  return join(" ", @_);
}

sub _vertex_str_to_vertices {
  return split(" ", shift());
}

sub _find_state_id_by_vertex_str {
  my ($self, $vertex_str) = @_;

  my $sth = $self->_dbh->prepare(q{
    SELECT state_id FROM State WHERE vertex_str = ?
  });

  return $self->_dbh->selectrow_array($sth, {}, $vertex_str);
}

sub _find_or_create_state_from_vertex_str {
  my ($self, $vertex_str) = @_;

  my $state_id = _find_state_id_by_vertex_str($self, $vertex_str);

  return $state_id if defined $state_id;

  $self->_dbh->begin_work();

  my $sth = $self->_dbh->prepare(q{
    INSERT INTO State(vertex_str) VALUES (?)
  });

  $sth->execute($vertex_str);

  $state_id = $self->_dbh->sqlite_last_insert_rowid();

  # NOTE: This would fail if one of the vertices does not exist
  # in the database yet, probably due to find_or_create_state_id
  # with vertices not passed in the constructor. It is not clear
  # whether that is a good thing to catch errors, or a usability
  # problem. Adding a trigger to Configuration or inserting the
  # vertices here is probably a performance problem though, so
  # adding vertices should be done by find_or_create_state_id if
  # at all.

  my $sth2 = $self->_dbh->prepare(q{
    INSERT INTO Configuration(state, vertex) VALUES (?, ?)
  });

  $sth2->execute($state_id, $_)
    for _vertex_str_to_vertices($vertex_str);

  $self->_dbh->commit();

  return $state_id;
}

sub _vertex_str_from_partial_list {
  my ($self, @vertices) = @_;

  return "" unless @vertices;

  my $escaped_roots = join ", ", map {
    $self->_dbh->quote($_)
  } @vertices;

  my ($vertex_str) = $self->_dbh->selectrow_array(qq{
    SELECT _canonical(GROUP_CONCAT(closure.e_reachable, " "))
    FROM Closure
    WHERE root IN ($escaped_roots)
  });

  return $vertex_str;
}

sub find_or_create_state_id {
  my ($self, @vertices) = @_;

  my $vertex_str = _vertex_str_from_partial_list($self, @vertices);

  return _find_or_create_state_from_vertex_str($self, $vertex_str);
}

sub vertices_in_state {
  my ($self, $state_id) = @_;

  return map { @$_ } $self->_dbh->selectall_array(q{
    SELECT vertex FROM Configuration WHERE state = ?
  }, {}, $state_id);
}

sub cleanup_dead_states {
  my ($self, $vertices_accept) = @_;

  $self->_dbh->sqlite_create_function( '_vertices_accept', 1, sub {
    my @vertices = _vertex_str_to_vertices(@_);
    return !! $vertices_accept->(@vertices);
  });

  $self->_dbh->begin_work();

  $self->_dbh->do(q{
    CREATE TEMPORARY TABLE accepting AS
    SELECT state_id AS state
    FROM State
    WHERE _vertices_accept(vertex_str)+0 = 1
  });

  my @accepting = map { @$_ } $self->_dbh->selectall_array(q{
    SELECT state FROM accepting
  });

  $self->_dbh->do(q{
    WITH RECURSIVE all_living(state) AS (
      SELECT state FROM accepting
      
      UNION
      
      SELECT src AS state
      FROM Transition
        INNER JOIN all_living
          ON (Transition.dst = all_living.state)
    )
    UPDATE Transition
    SET dst = ?
    WHERE dst NOT IN (SELECT state FROM all_living)
  }, {}, $self->dead_state_id);

  $self->_dbh->do(q{
    DROP TABLE accepting;
  });

  $self->_dbh->commit();

  # TODO: is there a better way to drop the function?
  $self->_dbh->sqlite_create_function( '_vertices_accept', 1, undef );

  return @accepting;
}

sub compute_some_transitions {
  my ($self, $limit) = @_;

  $limit //= 1_000;

  my $sth = $self->_dbh->prepare_cached(q{
    SELECT
        s.state_id AS src 
      , i.value AS input
      , _canonical(GROUP_CONCAT(closure.e_reachable, " "))
          AS dst_vertex_str
    FROM 
      state s 
      CROSS JOIN input i
      LEFT JOIN configuration c
        ON (s.state_id = c.state)
      LEFT JOIN match m
        ON (m.vertex = c.vertex AND m.input = i.value)
      LEFT JOIN edge
        ON (m.vertex = edge.src)
      LEFT JOIN closure
        ON (edge.dst = closure.root)
      LEFT JOIN transition t
        ON (t.src = s.state_id AND t.input = i.value)
    WHERE
      t.dst IS NULL
    GROUP BY
      s.state_id, i.rowid
    ORDER BY
      s.state_id, i.rowid
    LIMIT ?
  });

  my @new = $self->_dbh->selectall_array($sth, {}, $limit);

  my $find_or_create = memoize(sub {
    _find_or_create_state_from_vertex_str($self, @_);
  });

  my $sth2 = $self->_dbh->prepare(q{
    INSERT INTO Transition(src, input, dst) VALUES (?, ?, ?)
  });

  my @transitions;

  for my $t (@new) {
    push @transitions, [(
      $t->[0],
      $t->[1],
      $find_or_create->($t->[2]),
    )];
  }

  $self->_dbh->begin_work();
  $sth2->execute(@$_) for @transitions;
  $self->_dbh->commit();

  return scalar @new;
}

sub transitions_as_3tuples {
  my ($self) = @_;

  return $self->_dbh->selectall_array(q{
    SELECT src, input, dst FROM transition
  });
}

sub transitions_as_5tuples {
  my ($self) = @_;

  return $self->_dbh->selectall_array(q{
    SELECT * FROM view_transitions_as_5tuples
  });
}

sub backup_to_file {
  my ($self, $schema_version, $file) = @_;
  die unless $schema_version eq 'v0';
  $self->_dbh->sqlite_backup_to_file($file);
}

# sub backup_to_dbh {
#   my ($self, $schema_version) = @_;
# 
#   die unless $schema_version eq 'v0';
# 
#   require File::Temp;
# 
#   my ($fh, $filename) = File::Temp::tempfile();
# 
#   $self->_dbh->sqlite_backup_to_file($filename);
# 
#   my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:');
# 
#   $dbh->sqlite_backup_from_file($filename);
# 
#   File::Temp::unlink0($fh, $filename);
# 
#   undef $fh;
# 
#   return $dbh;
# }

1;

__END__

=head1 NAME

Algorithm::ConstructDFA2 - Deterministic finite automaton construction

=head1 SYNOPSIS

  use Algorithm::ConstructDFA2;

  my $dfa = Algorithm::ConstructDFA2->new(
    input_alphabet     => [ @symbols ],
    input_vertices     => [ qw/ 2 3 4 / ],
    input_edges        => [ [ 2, 3 ], [ 3, 4 ] ],

    vertex_nullable    => sub($vertex)         { ... },
    vertex_matches     => sub($vertex, $input) { ... },

    storage_dsn        => 'dbi:SQLite:dbname=...',
  );

  my $start_id = $dfa->find_or_create_state_id(qw/ 2 /);

  while (my $count = $dfa->compute_some_transitions(1_000)) {
    ...
  }

  my @accepting = $dfa->cleanup_dead_states(sub(@vertices) {
    ...
  });

=head1 DESCRIPTION

This module computes deterministic finite automata from equivalent
non-deterministic finite automata. The input NFA must be expressed
as directed graph with labeled vertices. Vertex labels indicate if
vertices match a particular terminal symbol from an input alphabet,
or match the empty string, meaning they can be crossed without any
input when matching a string.

This is slightly different from how NFA graphs are usually encoded
in literature (as graph with labeled edges), but the conversion is
straightforward (turn edges into additional vertices). Finding a
suitable alphabet is more difficult, L<Set::IntSpan::Partition> can
help with that (the module splits sets of sets of terminals like
"letters" and "digits" and "hexdigits" into non-overlapping sets,
each of which can then be used as a terminal for this module).

DFAs can be exponentially larger than equivalent NFAs; to accomodate
large or complicated NFAs, computed data is held in a SQLite database
to reduce memory use. Since a DFA is basically just the result of
exhaustively computing cross-products, most computation is done in
SQL, leaving only minimal Perl code.

=head1 CONSTRUCTOR

=over

=item new(%options)

The C<%options> hash supports the following keys:

=over

=item C<input_vertices>

Array of vertices (unsigned integers) in the input graph.

=item C<input_edges>

Array of edges (arrays of two vertices) in the input graph.

=item C<input_alphabet>

Array of terminal symbols (unsigned integers).

=item C<vertex_nullable>

Code reference called for each vertex in the input graph. Should
return a true value if and only if the vertex matches the empty
string.

=item C<vertex_matches>

Code reference called for each pair of input vertex and input symbol
from the input alphabet. Should return a true value if and only if
the vertex matches the input symbol.

=item C<storage_dsn>

Database to use for computations, C<dbi:SQLite:dbname=:memory:> by
default.

=back

=back

=head1 METHODS

=over

=item $dfa->find_or_create_state_id(@vertices)

Given a list of vertices, computes a new state, adds it to the
automaton if it does not already exist, and returns an identifier
for the state. This is used to create a start state in the DFA.

=item $dfa->compute_some_transitions($limit)

Computes up to C<$limit> additional transitions and returns the
number of transitions actually computed. A return value of zero
indicates that all transitions have been computed.

=item $dfa->dead_state_id()

Returns the state identifier for a fixed dead state (from which
no accepting configuration can be reached).

=item $dfa->cleanup_dead_states(\&vertices_accept)

Given a code reference that takes a list of vertices and returns
true if and only if the vertices are an accepting configuration,
this method changes the automaton so that dead states have no
transitions to different dead states.

If, for example, the input NFA has a special "final" vertex that
indicates acceptance when reached, the code reference would check
if the vertex list contains this vertex.

=item $dfa->transitions_as_3tuples()

Returns a list of all transitions computed so far as. Transitions
are arrays with three identifiers for the source state, the input
symbol, and the destination state.

  for my $transition ( $dfa->transitions_as_3tuples() ) {
    my ($src_state, $input, $dst_state) = @$transition;
    ...
  }

=item $dfa->vertices_in_state($state_id)

Returns a list of vertices in the state C<$state_id>.

=item $dfa->transitions_as_5tuples()

Returns a list of all transitions computed so far as. Transitions
are arrays with five identifiers: the source state, an input vertex
included in the source state, the input symbol, the destination state
and an input vertex included in the destination state.

  for my $transition ( $dfa->transitions_as_5tuples() ) {
    my ($src_state, $src_vertex, $input, $dst_state, $dst_vertex) =
      @$transition;
    ...
  }

Note that unlike C<transitions_as_3tuples> this omits transitions
involving the main dead state.

=item $dfa->backup_to_file('v0', $file)

Create a backup of the database used to store input and computed data
into C<$file>. The first parameter must be C<v0> and indicates the
version of the database schema.

=back

=head1 TODO

=over

=item * It does not make sense for C<transitions_as_5tuples> and its
        companions to return a list for large automata. But short of
        returning the DBI statement handle there does not seem to be
        a good way to return something more lazy.

=item * ...

=back

=head1 BUG REPORTS

Please report bugs in this module via
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-ConstructDFA2>

=head1 SEE ALSO

=over

=item * L<Set::IntSpan::Partition> - Useful to create alphabets from sets

=item * L<Acme::Partitioner> - Useful to minimise automata

=item * L<Algorithm::ConstructDFA> - obsolete predecessor

=item * L<Algorithm::ConstructDFA::XS> - obsolete predecessor

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Slaven Rezic for bug reports.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2017-2018 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
