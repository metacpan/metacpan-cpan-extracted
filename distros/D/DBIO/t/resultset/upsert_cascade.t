use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;

# ADR 0036 section 1: the cascading upsert -- nested data in \%col_data makes
# upsert write the parts too.
#
# What is promised, and POD is held to exactly these words: N atomic upserts,
# in dependency order, inside one transaction -- all-or-nothing, and every part
# individually free of the read-then-write race. Deliberately NOT "an atomic
# upsert": no engine has a multi-table one.
#
# So the subject of this file is the *sequence*: which statement runs when, and
# whose key reaches whose foreign key. Rendering the conflict clause belongs to
# the driver SQLMaker and is tested in the driver dists.

# A belongs_to onto a source that has no primary key at all. It exists only to
# make the "the cascade can never name this row" shape reachable -- the shared
# test schema has no relationship to NoPrimaryKey -- and is added to the
# registered source rather than to the Result class, which is composed away.
sub add_nokey_rel {
  my $schema = shift;
  $schema->source('Track')->add_relationship(
    'nokey',
    'DBIO::Test::Schema::NoPrimaryKey',
    { 'foreign.foo' => 'self.position' },
    { accessor => 'single', is_foreign_key_constraint => 1 },
  );
  return $schema;
}

# Stand-in for a driver SQLMaker, same shape as t/resultset/upsert.t: it
# consumes $options->{on_conflict}, so the structure that crosses the seam is
# visible per statement, and marks the SQL so the clause is provably placed.
{
  package DBIO::Test::CascadeSQLMaker;
  use base 'DBIO::SQLMaker';
  our @SEEN;
  our $DIE_ON = '';

  sub insert {
    my ($self, $table, $data, $options) = @_;

    my $on_conflict = $options ? delete $options->{on_conflict} : undef;
    return $self->next::method($table, $data, $options) unless $on_conflict;

    my $name = ref $table eq 'SCALAR' ? $$table : $table;
    die "the engine refused to write $name\n" if $DIE_ON and $name eq $DIE_ON;

    push @SEEN, { table => $name, %$on_conflict };
    my ($sql, @bind) = $self->next::method($table, $data, $options);
    return ("$sql /*CONFLICT*/", @bind);
  }
}

sub cascade_schema {
  my $schema  = DBIO::Test->init_schema;
  my $storage = $schema->storage;
  $storage->sql_maker_class('DBIO::Test::CascadeSQLMaker');
  $storage->_use_supports_upsert(1);
  @DBIO::Test::CascadeSQLMaker::SEEN = ();
  $DBIO::Test::CascadeSQLMaker::DIE_ON = '';
  $storage->reset_captured;
  return $schema;
}

# The captured statement log reduced to what a cascade is about: the op, and
# for a write the table it wrote.
sub sequence {
  map {
    $_->{op} eq 'insert'
      ? 'insert ' . ( $_->{sql} =~ m/^INSERT INTO "?(\w+)"?/ ? $1 : '?' )
      : $_->{op}
  } $_[0]->storage->captured_queries;
}

# The bind values of one captured statement, keyed by column.
sub bound {
  my $q = shift;
  return { map {; $_->[0]{dbic_colname} => $_->[1] } @{ $q->{bind} || [] } };
}

sub writes { grep { $_->{op} eq 'insert' } $_[0]->storage->captured_queries }

# --- 1. dependency order -------------------------------------------------

# The ADR's own example. belongs_to first (its key becomes our foreign key),
# then us, then has_many (our key becomes theirs) -- the split
# DBIO::Row::insert performs for multi-create, on data instead of objects.
{
  my $s = cascade_schema();
  $s->storage->set_auto_increment(artist => 500);
  $s->storage->set_auto_increment(track  => 900);

  my $cd = $s->resultset('CD')->upsert(
    {
      title  => 'Bad',
      year   => 1987,
      artist => { name => 'Michael Jackson' },
      tracks => [
        { position => 1, title => 'Bad' },
        { position => 2, title => 'Speed Demon' },
      ],
    },
    {
      conflict_target => [qw/ artist title /],
      relations => {
        artist => { key => 'artist_name' },
        tracks => { conflict_target => [qw/ cd position /] },
      },
    },
  );

  is_deeply [ sequence($s) ], [
    'txn_begin',
    'insert artist',
    'insert cd',
    'insert track',
    'insert track',
    'txn_commit',
  ], 'belongs_to before the row, has_many after it, all in one transaction';

  my @w = writes($s);
  is bound($w[1])->{artist}, 500,
    "the artist part's key is what the cd row is written with";
  is bound($w[2])->{cd}, 1, "the cd's key is what the first track is written with";
  is bound($w[3])->{cd}, 1, '... and the second';
  is bound($w[2])->{position}, 1, 'the children keep the order they were listed in';
  is bound($w[3])->{position}, 2, '... second one too';

  # This is the whole point of the feature. update_or_create would SELECT
  # before each of these four writes and act on what it read.
  is scalar(grep { $_->{op} eq 'select' } $s->storage->captured_queries), 0,
    'not one part is looked up first -- each is a single atomic statement';

  isa_ok $cd, 'DBIO::Test::Schema::CD', 'the return value';
  is $cd->title, 'Bad', 'and it is the top-level row';
  is $cd->get_column('artist'), 500, 'carrying the foreign key the cascade set';
}

# Nesting is not limited to one level: a part may nest its own parts, and
# relations nests with it. The order is still one chain of dependencies.
{
  my $s = cascade_schema();
  $s->storage->set_auto_increment(artist => 700);

  $s->resultset('Track')->upsert(
    {
      position => 3,
      title    => 'Man in the Mirror',
      cd       => {
        title  => 'Bad',
        year   => 1987,
        artist => { name => 'Michael Jackson' },
      },
    },
    {
      conflict_target => [qw/ cd position /],
      relations => {
        cd => {
          conflict_target => [qw/ artist title /],
          relations       => { artist => { key => 'artist_name' } },
        },
      },
    },
  );

  is_deeply [ sequence($s) ],
    [ 'txn_begin', 'insert artist', 'insert cd', 'insert track', 'txn_commit' ],
    'a part of a part is written first of all -- the chain resolves depth-first';

  my @w = writes($s);
  is bound($w[1])->{artist}, 700, 'the deepest key reaches the middle row';
  is bound($w[2])->{cd}, 1, '... and the middle key reaches the top row';
}

# might_have: the child hangs off us, so it is written after us -- even when
# its only column is the foreign key it is handed.
{
  my $s = cascade_schema();

  $s->resultset('CD')->upsert(
    { cdid => 7, title => 'Bad', year => 1987, artwork => {} },
  );

  is_deeply [ sequence($s) ],
    [ 'txn_begin', 'insert cd', 'insert cd_artwork', 'txn_commit' ],
    'a might_have part is written after the row it hangs off';

  my @w = writes($s);
  is bound($w[1])->{cd_id}, 7,
    'a part whose only column is the foreign key is still a real part';
}

# has_many writes the children that were listed. It never deletes the ones
# that were not -- "replace the set" is set_$rel semantics and something else
# entirely, and implicit deletion would be the nastiest surprise here.
{
  my $s = cascade_schema();

  $s->resultset('CD')->upsert(
    {
      cdid   => 3,
      title  => 'Bad',
      year   => 1987,
      tracks => [ { position => 1, title => 'Bad' } ],
    },
    { relations => { tracks => { conflict_target => [qw/ cd position /] } } },
  );

  is_deeply [ sequence($s) ],
    [ 'txn_begin', 'insert cd', 'insert track', 'txn_commit' ],
    'only the listed child is written';

  is scalar(grep { $_->{op} =~ m/^(?:delete|update)$/ } $s->storage->captured_queries),
    0, 'and nothing at all is deleted -- unlisted children are left untouched';
}

# A ref under a key that happens to name a relationship is not automatically a
# part: CD's 'artist' is a column AND a belongs_to, and a literal bind under it
# is a value for the column. Same criterion DBIO::Row::new uses to sort
# multi-create data -- get this wrong and a plain flat upsert starts cascading.
{
  my $s = cascade_schema();

  $s->resultset('CD')->upsert(
    { cdid => 3, title => 'Bad', year => 1987, artist => \[ '?', 5 ] },
  );

  is_deeply [ sequence($s) ], [ 'insert cd' ],
    'a literal under a relationship-named column is a column, not a cascade';
  is scalar @DBIO::Test::CascadeSQLMaker::SEEN, 1, 'and stays one statement';
}

# --- 2. what crosses the seam per part -----------------------------------

# Each part is a real upsert with its own conflict target: the caller states
# it, the cascade never infers it from the relationship.
{
  my $s = cascade_schema();

  $s->resultset('CD')->upsert(
    {
      title  => 'Bad',
      year   => 1987,
      artist => { name => 'Michael Jackson', rank => 1 },
      tracks => [ { position => 1, title => 'Bad' } ],
    },
    {
      conflict_target => [qw/ artist title /],
      relations => {
        artist => { key => 'artist_name' },
        tracks => { conflict_target => [qw/ cd position /] },
      },
    },
  );

  my @seen = @DBIO::Test::CascadeSQLMaker::SEEN;
  is scalar @seen, 3, 'every part carries a conflict clause of its own';

  is_deeply $seen[0], {
    table  => 'artist',
    target => { constraint => 'artist_name', columns => ['name'] },
    action => 'update',
    set    => { rank => { -attempted => 'rank' } },
  }, 'the belongs_to part conflicts on the constraint it was given';

  is_deeply $seen[1]{target}, [qw/ artist title /],
    'the top-level row keeps its own target';
  is_deeply $seen[1]{set}, { year => { -attempted => 'year' } },
    '... and the foreign key the cascade set is not something to update';

  is_deeply $seen[2], {
    table  => 'track',
    target => [qw/ cd position /],
    action => 'update',
    set    => { title => { -attempted => 'title' } },
  }, 'the has_many part conflicts on the columns it was given';
}

# A part identified entirely by its own target -- the lookup row a belongs_to
# almost always is -- would leave the conflict branch with nothing to set.
# Flat, upsert refuses that and points at on_conflict => 'nothing'. In a
# cascade that is not a choice the caller has: DO NOTHING writes no row, and a
# part something hangs off has to be nameable. So the branch re-asserts the
# target instead, which is a no-op on the value and keeps the row named.
{
  my $s = cascade_schema();

  $s->resultset('CD')->upsert(
    { title => 'Bad', year => 1987, artist => { name => 'Michael Jackson' } },
    {
      conflict_target => [qw/ artist title /],
      relations       => { artist => { key => 'artist_name' } },
    },
  );

  is_deeply $DBIO::Test::CascadeSQLMaker::SEEN[0]{set},
    { name => { -attempted => 'name' } },
    'a key-only part re-asserts its target rather than setting nothing';

  # ... and the same rule holds for the top-level row of a cascade, whose
  # every column can equally be target plus foreign key.
  my $s2 = cascade_schema();
  $s2->resultset('CD')->upsert(
    { title => 'Bad', artist => { name => 'Michael Jackson' } },
    {
      conflict_target => [qw/ artist title /],
      relations       => { artist => { key => 'artist_name' } },
    },
  );
  is_deeply $DBIO::Test::CascadeSQLMaker::SEEN[1]{set},
    { artist => { -attempted => 'artist' }, title => { -attempted => 'title' } },
    'and so does the top-level row when it has nothing else to say';
}

# Identity is bought only where it is needed. A leaf part is written with
# result => 'void': one round-trip, no RETURNING tail on a row nobody will
# ever see. The rows whose key the cascade has to hand on do ask for it.
{
  my $s = cascade_schema();
  $s->storage->_use_insert_returning(1);
  $s->storage->mock_persistent(qr/INSERT INTO "artist"/, [ [ 42 ] ]);
  $s->storage->mock_persistent(qr/INSERT INTO cd/, [ [ 9 ] ]);

  $s->resultset('CD')->upsert(
    {
      title  => 'Bad',
      year   => 1987,
      artist => { name => 'Michael Jackson', rank => 1 },
      tracks => [ { position => 1, title => 'Bad' } ],
    },
    {
      conflict_target => [qw/ artist title /],
      relations => {
        artist => { key => 'artist_name' },
        tracks => { conflict_target => [qw/ cd position /] },
      },
    },
  );

  my @w = writes($s);
  like $w[0]{sql}, qr/RETURNING "artistid"/,
    'a part whose key becomes a foreign key asks the engine to name it';
  like $w[1]{sql}, qr/RETURNING "cdid"/,
    '... and so does a row that has children';
  unlike $w[2]{sql}, qr/RETURNING/i,
    'a leaf part spends nothing on an identity nobody asked for';

  is bound($w[1])->{artist}, 42, 'the returned key is the one that is handed on';
  is bound($w[2])->{cd}, 9, '... at every level';
}

# --- 3. the transaction ---------------------------------------------------

# All-or-nothing. A part that blows up takes the whole cascade with it.
{
  my $s = cascade_schema();
  $DBIO::Test::CascadeSQLMaker::DIE_ON = 'track';

  throws_ok {
    $s->resultset('CD')->upsert(
      {
        cdid   => 3,
        title  => 'Bad',
        year   => 1987,
        tracks => [ { position => 1, title => 'Bad' } ],
      },
      { relations => { tracks => { conflict_target => [qw/ cd position /] } } },
    );
  } qr/the engine refused to write track/, 'a failing part propagates';

  is_deeply [ sequence($s) ], [ 'txn_begin', 'insert cd', 'txn_rollback' ],
    'and the row already written is rolled back with it';
}

# Already inside a transaction? The cascade JOINS it rather than opening one
# of its own, so a failing cascade rolls the caller's outer work back too.
# Deliberately no savepoint magic -- a caller wanting isolation opens theirs.
{
  my $s = cascade_schema();
  $DBIO::Test::CascadeSQLMaker::DIE_ON = 'track';

  throws_ok {
    $s->txn_do(sub {
      $s->resultset('Artist')->upsert({ artistid => 1, name => 'first' });
      $s->resultset('CD')->upsert(
        {
          cdid   => 3,
          title  => 'Bad',
          year   => 1987,
          tracks => [ { position => 1, title => 'Bad' } ],
        },
        { relations => { tracks => { conflict_target => [qw/ cd position /] } } },
      );
    });
  } qr/the engine refused to write track/, 'the failure reaches the caller';

  is_deeply [ sequence($s) ],
    [ 'txn_begin', 'insert artist', 'insert cd', 'txn_rollback' ],
    'one transaction, not a nested one -- the outer work goes back too';
}

# The happy path inside a caller transaction commits exactly once.
{
  my $s = cascade_schema();

  $s->txn_do(sub {
    $s->resultset('CD')->upsert(
      {
        cdid   => 3,
        title  => 'Bad',
        year   => 1987,
        tracks => [ { position => 1, title => 'Bad' } ],
      },
      { relations => { tracks => { conflict_target => [qw/ cd position /] } } },
    );
  });

  is_deeply [ sequence($s) ],
    [ 'txn_begin', 'insert cd', 'insert track', 'txn_commit' ],
    'joining a caller transaction means one BEGIN and one COMMIT';
}

# --- 4. every refusal, and all of them before the first statement --------

my $cs  = cascade_schema();
my $cds = $cs->resultset('CD');

# A count over N statements is not a count, and void would withhold the very
# identity the cascade needs to link the parts.
for my $shape (qw/ count void /) {
  throws_ok {
    $cds->upsert(
      { title => 'x', year => 1, artist => { name => 'y' } },
      {
        conflict_target => [qw/ artist title /],
        result          => $shape,
        relations       => { artist => { key => 'artist_name' } },
      },
    );
  } qr/result => '$shape' cannot be used with nested relationship data/,
    "result => $shape is refused with nested data";
}

throws_ok {
  $cds->upsert(
    { title => 'x', year => 1, artist => { name => 'y' } },
    { fallback => 'update_or_create', relations => { artist => { key => 'artist_name' } } },
  );
} qr/fallback => 'update_or_create' cannot express a cascade/,
  'the fallback has no way to state a target per part, so it is refused';

# The three-way primary-key default applies per part: no target and no key in
# the part's data is the same silent no-op it is at the top level.
throws_ok {
  $cds->upsert(
    { title => 'x', year => 1, artist => { name => 'y' } },
    { conflict_target => [qw/ artist title /] },
  );
} qr/no conflict target given for Artist for the nested 'artist'/,
  'a part with no target and no primary key in its data throws';

throws_ok {
  $cds->upsert(
    { title => 'x', year => 1, artist => { name => 'y' } },
    { conflict_target => [qw/ artist title /] },
  );
} qr/relations => \{ 'artist' => \{ key => \$constraint \} \}/,
  '... and the message names where to put the target';

throws_ok {
  $cs->resultset('Artist')->upsert(
    { artistid => 1, name => 'x', cds => [ { title => 'y', year => 1 } ] },
  );
} qr/no conflict target given for CD for the nested 'cds'/,
  'the same rule holds for a has_many part';

# Identity is a precondition, not a nicety, and it is decided from static
# metadata -- so it fails on the first call in development, never
# data-dependently in production.
throws_ok {
  $cds->upsert(
    { title => 'x', year => 1, artist => { name => 'y', rank => 2 } },
    {
      conflict_target => [qw/ artist title /],
      relations       => { artist => { conflict_target => 'any' } },
    },
  );
} qr/conflict_target => 'any'.*cannot take part in a cascade/s,
  "'any' cannot name the row it wrote, so it cannot feed a foreign key";

throws_ok {
  add_nokey_rel($cs)->resultset('Track')->upsert(
    { position => 1, title => 't', nokey => { foo => 1, bar => 2, baz => 3 } },
    {
      conflict_target => [qw/ cd position /],
      relations       => { nokey => { key => 'foo_bar' } },
    },
  );
} qr/the cascade needs the key of the row written for NoPrimaryKey/,
  'a part on a source without a primary key can never be named';

throws_ok {
  $cds->upsert(
    { cdid => 3, title => 'x', year => 1, tracks => [ { position => 1, title => 'y' } ] },
    {
      on_conflict => 'nothing',
      relations   => { tracks => { conflict_target => [qw/ cd position /] } },
    },
  );
} qr/on_conflict => 'nothing' cannot take part in a cascade/,
  'DO NOTHING may write no row, so nothing can hang off it';

# many_to_many would mean writing link rows, which reopens the deletion
# question has_many is deliberately kept out of.
throws_ok {
  $cds->upsert(
    { cdid => 3, title => 'x', year => 1, producers => [ { name => 'p' } ] },
  );
} qr/'producers' is a many_to_many accessor/,
  'many_to_many is out of scope and says so, rather than "no such column"';

# A Result object is already a decision about identity; "write this" and
# "link this" are different asks and guessing between them is the DWIM this
# API exists to avoid.
{
  my $artist = $cs->resultset('Artist')->new_result({ artistid => 1, name => 'y' });
  throws_ok {
    $cds->upsert(
      { title => 'x', year => 1, artist => $artist },
      { conflict_target => [qw/ artist title /] },
    );
  } qr/the nested 'artist' is a DBIO::Test::Schema::Artist object/,
    'a Result object in the nested data throws instead of being guessed at';
}

# Relationship kind and data shape have to agree.
throws_ok {
  $cds->upsert(
    { cdid => 3, title => 'x', year => 1, tracks => { position => 1, title => 'y' } },
  );
} qr/the nested 'tracks' is a single hashref, but 'tracks' is a has_many/,
  'a has_many given a hashref throws';

throws_ok {
  $cds->upsert(
    { title => 'x', year => 1, artist => [ { name => 'y' } ] },
    { conflict_target => [qw/ artist title /] },
  );
} qr/the nested 'artist' is a list, but 'artist' is not a has_many/,
  'a belongs_to given a list throws';

# Without a reverse relationship nothing links the children to the row they
# were nested under -- they would be written as orphans.
throws_ok {
  $cs->resultset('Artist')->upsert(
    { artistid => 1, name => 'x', cds_cref_cond => [ { cdid => 1, title => 'y', year => 1 } ] },
  );
} qr/'cds_cref_cond'.*has no reverse relationship back to Artist/s,
  'a has_many with no way back throws rather than writing orphans';

# The per-relation entries are checked as strictly as the top-level options.
throws_ok {
  $cds->upsert(
    { title => 'x', year => 1, artist => { name => 'y' } },
    {
      conflict_target => [qw/ artist title /],
      relations       => { artist => { key => 'artist_name', result => 'void' } },
    },
  );
} qr/unknown option\(s\) 'result' for the nested 'artist'/,
  'result is a decision about the whole call, not about one part';

throws_ok {
  $cds->upsert(
    { title => 'x', year => 1, artist => { name => 'y' } },
    {
      conflict_target => [qw/ artist title /],
      relations => { artist => { key => 'artist_name', conflict_target => ['name'] } },
    },
  );
} qr/mutually exclusive, also for the nested 'artist'/,
  'key and conflict_target are exclusive per part too';

throws_ok {
  $cds->upsert(
    { title => 'x', year => 1, artist => { name => 'y' } },
    { conflict_target => [qw/ artist title /], relations => { artist => [] } },
  );
} qr/relations.*=> \{ 'artist' => \.\.\. \} must be a hashref/,
  'a per-relation entry that is not a hashref throws';

throws_ok {
  $cds->upsert(
    { title => 'x', year => 1, artist => { name => 'y' } },
    {
      conflict_target => [qw/ artist title /],
      relations => { artist => { key => 'artist_name' }, genre => { key => 'genre_name' } },
    },
  );
} qr/relations.*names 'genre', but there is no nested data for it/s,
  'a per-relation target with no part to apply it to is a typo, not a no-op';

# Nothing above got as far as a statement -- that is the point of checking it
# from static metadata.
is scalar($cs->storage->captured_queries), 0,
  'not one of those refusals issued a statement, or even opened a transaction';

# ... including when the *second* part is the bad one. Refusing while the
# first part is already written would be a cascade that fails in production
# rather than in development.
{
  my $s = cascade_schema();

  throws_ok {
    $s->resultset('CD')->upsert(
      {
        title  => 'x',
        year   => 1,
        artist => { name => 'y' },
        genre  => { name => 'Pop' },
      },
      {
        conflict_target => [qw/ artist title /],
        relations       => { artist => { key => 'artist_name' } },
      },
    );
  } qr/for Genre for the nested 'genre'/,
    'a bad second part is caught';

  is scalar($s->storage->captured_queries), 0,
    '... before the good first part was written, not after';
}

# --- update_where in a cascade -------------------------------------------

# A condition is a decision about the whole call, like on_conflict, update and
# result -- and for a part it would be worse than pointless: a belongs_to part
# whose update may not happen is a part whose key may not exist.
throws_ok {
  $cds->upsert(
    { title => 'x', year => 1, artist => { name => 'y' } },
    {
      conflict_target => [qw/ artist title /],
      relations       => { artist => { key => 'artist_name', update_where => { rank => 1 } } },
    },
  );
} qr/unknown option\(s\) 'update_where' for the nested 'artist'/,
  'a per-relation update_where is refused like every other whole-call option';

# At the top of a cascade the condition is refused exactly where DO NOTHING is
# refused, and for the same reason: rows hang off this one, and a conditional
# update may write none. Whether the condition holds is a fact about the
# stored data, so allowing it would move the failure out of development and
# into the day the condition first comes back false.
{
  my $s = cascade_schema();
  $s->storage->_use_supports_upsert_where(1);

  throws_ok {
    $s->resultset('CD')->upsert(
      {
        cdid   => 1,
        title  => 'x',
        year   => 1,
        tracks => [ { position => 1, title => 'y' } ],
      },
      {
        update_where => { year => { '<' => { -attempted => 'year' } } },
        relations    => { tracks => { conflict_target => [qw/ cd position /] } },
      },
    );
  } qr/update_where cannot take part in a cascade with nested rows that depend on this one/,
    'a conditional update on a row the children need throws';

  is scalar($s->storage->captured_queries), 0,
    '... before the transaction, not inside it';
}

# ... but a cascade whose top row nothing depends on is a different shape: the
# belongs_to parts are written first and unconditionally, and the conditional
# row at the end may write nothing and hand back undef, exactly as it does
# flat. Refusing that would be stricter than the rule for DO NOTHING, which is
# the same situation.
{
  my $s = cascade_schema();
  $s->storage->_use_supports_upsert_where(1);
  $s->storage->set_auto_increment(artist => 700);

  my $cond = { year => { '<' => { -attempted => 'year' } } };
  $s->resultset('CD')->upsert(
    {
      title  => 'Bad',
      year   => 1987,
      artist => { name => 'Michael Jackson' },
    },
    {
      conflict_target => [qw/ artist title /],
      update_where    => $cond,
      relations       => { artist => { key => 'artist_name' } },
    },
  );

  is_deeply [ sequence($s) ], [
    'txn_begin', 'insert artist', 'insert cd', 'txn_commit',
  ], 'the cascade runs, the condition and all';

  my @seen = @DBIO::Test::CascadeSQLMaker::SEEN;
  ok ! exists $seen[0]{where},
    'the belongs_to part is written unconditionally -- the condition is not inherited';
  is_deeply $seen[1]{where}, $cond,
    '... and reaches only the row it was given for';
}

# No capability, no cascade -- and not even a transaction to show for it.
{
  my $s = DBIO::Test->init_schema;
  $s->storage->reset_captured;

  throws_ok {
    $s->resultset('CD')->upsert(
      { title => 'x', year => 1, artist => { name => 'y' } },
      {
        conflict_target => [qw/ artist title /],
        relations       => { artist => { key => 'artist_name' } },
      },
    );
  } qr/does not declare the supports_upsert capability/,
    'a cascade on an engine without an atomic upsert throws';

  is scalar($s->storage->captured_queries), 0,
    'and does not open a transaction it would only have to roll back';
}

# The batch name is reserved (ADR 0036 section 1) and still unimplemented.
# When it appears, nested data has to throw there: a batch of trees is a list
# of independent cascades, which is a different feature again.
ok ! DBIO::ResultSet->can('upsert_all'),
  'upsert_all is still only a reserved name -- when it lands, nested data must throw there';

done_testing;
