use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;
use DBIO::SQLMaker ();
use DBIO::Storage::DBI::Capabilities ();

# ADR 0036: atomic upsert is gated by declared capabilities, both default 0 --
# supports_upsert for the conflict clause itself, and supports_upsert_where
# for the one part of it a driver could drop without any symptom. This file
# covers the capability plumbing and the guards that keep an on_conflict
# structure away from a SQL generator that cannot render it. The
# ResultSet-level API lives in t/resultset/upsert.t.

my $schema = DBIO::Test->init_schema;

# --- 1. the capability is part of the declared contract surface ----------

# the capability is named supports_upsert, so the two-tier accessors spell
# out as _supports_supports_upsert / _use_supports_upsert -- exactly like the
# existing supports_if_exists (ADR 0026)
can_ok 'DBIO::Storage::DBI::Capabilities', '_supports_supports_upsert';
can_ok 'DBIO::Storage::DBI::Capabilities', '_use_supports_upsert';
can_ok 'DBIO::Storage::DBI::Capabilities', '_determine_supports_supports_upsert';

is( DBIO::Storage::DBI::Capabilities->_determine_supports_supports_upsert, 0,
  'the default _determine_supports_supports_upsert is conservative (0): an '
. 'engine has no atomic upsert until its driver says otherwise' );

# The conditional conflict branch (DO UPDATE ... WHERE) is the one
# dialect difference with a flag of its own, because it is the only one a
# driver can ignore silently: the statement stays valid and writes
# unconditionally. Same two-tier shape, same conservative default.
can_ok 'DBIO::Storage::DBI::Capabilities', '_supports_supports_upsert_where';
can_ok 'DBIO::Storage::DBI::Capabilities', '_use_supports_upsert_where';
can_ok 'DBIO::Storage::DBI::Capabilities', '_determine_supports_supports_upsert_where';

is( DBIO::Storage::DBI::Capabilities->_determine_supports_supports_upsert_where, 0,
  'the default _determine_supports_supports_upsert_where is conservative (0)' );

# --- 2. two-tier accessor plumbing on a live storage object --------------

{
  my $storage = $schema->storage;

  is $storage->_use_supports_upsert, 0,
    'stock storage does not advertise supports_upsert';

  $storage->_use_supports_upsert(1);
  is $storage->_use_supports_upsert, 1, '_use_supports_upsert(1) is honoured';

  # explicitly opting out must read as 0, not as "unset" (which would fall
  # through to _determine_supports_* again)
  $storage->_use_supports_upsert(0);
  is $storage->_use_supports_upsert, 0, '_use_supports_upsert(0) is honoured';

  $storage->_use_supports_upsert(undef);
  is $storage->_use_supports_upsert, 0,
    'clearing _use_ falls back through _supports_upsert to the determiner';
}

# A driver opting in at class level, the ADR 0026 shape.
{
  package DBIO::Test::UpsertStorage::Declared;
  our @ISA = ('DBIO::Test::Storage');
  __PACKAGE__->_use_supports_upsert(1);
}
{
  my $storage = DBIO::Test::UpsertStorage::Declared->new($schema);
  is $storage->_use_supports_upsert, 1,
    'a class-level __PACKAGE__->_use_supports_upsert(1) reaches instances';

  $storage->_use_supports_upsert(0);
  is $storage->_use_supports_upsert, 0,
    'a per-instance value overrides the class declaration';
}

# A driver version-gating it through _determine_supports_*, the shape
# PostgreSQL uses for insert_returning.
{
  package DBIO::Test::UpsertStorage::Determined;
  our @ISA = ('DBIO::Test::Storage');
  sub _determine_supports_supports_upsert { 1 }
}
{
  my $storage = DBIO::Test::UpsertStorage::Determined->new($schema);
  is $storage->_supports_supports_upsert, 1,
    '_supports_supports_upsert asks _determine_supports_supports_upsert';
  is $storage->_use_supports_upsert, 1,
    'with no _use_ value set, _use_supports_upsert falls through to the determiner';
}

# --- 3. the storage refuses to emit on_conflict without the capability ---

# Belt and braces behind the ResultSet gate: even a direct storage->insert
# call must not hand an on_conflict structure to a SQL generator whose driver
# never declared it.
{
  my $storage = $schema->storage;
  is $storage->_use_supports_upsert, 0, 'capability is off for this check';

  throws_ok {
    $storage->insert(
      $schema->source('Artist'),
      { artistid => 1, name => 'x' },
      { on_conflict => { target => ['artistid'], action => 'update', set => {} } }
    );
  } qr/does not declare the supports_upsert capability/,
    'storage->insert refuses an on_conflict structure without the capability';
}

# The two capabilities are independent gates: rendering conflict clauses does
# not imply rendering conditional ones, and the where key must not slip
# through on the strength of supports_upsert alone. Dropping it would leave a
# valid, unconditional UPDATE -- the failure mode this second flag exists for.
{
  my $s       = DBIO::Test->init_schema;
  my $storage = $s->storage;
  $storage->_use_supports_upsert(1);
  is $storage->_use_supports_upsert_where, 0,
    'declaring supports_upsert says nothing about conditional updates';

  throws_ok {
    $storage->insert(
      $s->source('Artist'),
      { artistid => 1, name => 'x' },
      { on_conflict => {
          target => ['artistid'],
          action => 'update',
          set    => { name => { -attempted => 'name' } },
          where  => { rank => 1 },
      } }
    );
  } qr/does not declare the supports_upsert_where capability/,
    'storage->insert refuses a conditional conflict branch without the flag';

  # with both declared the structure is passed on, and it is the SQL generator
  # that decides what to do with it
  $storage->_use_supports_upsert_where(1);
  throws_ok {
    $storage->insert(
      $s->source('Artist'),
      { artistid => 1, name => 'x' },
      { on_conflict => {
          target => ['artistid'],
          action => 'update',
          set    => { name => { -attempted => 'name' } },
          where  => { rank => 1 },
      } }
    );
  } qr/does not implement the 'on_conflict' insert option/,
    'with both flags the structure reaches the SQL generator, which refuses it here';
}

# ... and independent in the other direction too. ADR 0036
# section 3 pins supports_upsert_where as a plain fact about the conditional
# branch, never derived from supports_upsert: a driver whose SQL generator
# renders the WHERE says so even where the upsert gate is closed for a reason
# of its own (PostgreSQL's also requires RETURNING, which is about naming the
# written row -- something a condition that does not hold has no need of, as
# it writes none). So this combination is a legal state, not a contradiction,
# and core still refuses on the supports_upsert gate, with THAT gate's
# message: the second flag is not there to repeat the first one's diagnosis.
{
  my $s       = DBIO::Test->init_schema;
  my $storage = $s->storage;
  $storage->_use_supports_upsert_where(1);

  is $storage->_use_supports_upsert_where, 1,
    'supports_upsert_where can be declared on its own';
  is $storage->_use_supports_upsert, 0,
    '... without dragging supports_upsert along with it';

  my $err = do {
    local $@;
    eval {
      $storage->insert(
        $s->source('Artist'),
        { artistid => 1, name => 'x' },
        { on_conflict => {
            target => ['artistid'],
            action => 'update',
            set    => { name => { -attempted => 'name' } },
            where  => { rank => 1 },
        } }
      );
    };
    "$@";
  };

  like $err, qr/does not declare the supports_upsert capability/,
    'the conflict clause is refused on the supports_upsert gate';
  unlike $err, qr/supports_upsert_where/,
    '... and not blamed on the flag that is declared';
}

# --- 4. the base SQLMaker refuses the option outright --------------------

# The conflict clause has no generic placement (before RETURNING on
# PostgreSQL, no target at all on MySQL), so the base generator does not
# render it. Reaching the generic insert path with the key still set means a
# driver declared supports_upsert without implementing the clause -- that has
# to be loud rather than silently dropped from the statement.
{
  my $sql_maker = DBIO::SQLMaker->new;

  throws_ok {
    $sql_maker->insert(
      'artist',
      { artistid => 1, name => 'x' },
      { on_conflict => { target => ['artistid'], action => 'update', set => {} } }
    );
  } qr/does not implement the 'on_conflict' insert option/,
    'the base SQLMaker throws on an on_conflict it cannot render';

  # ... and is unaffected without it
  my ($sql) = $sql_maker->insert('artist', { artistid => 1 });
  like $sql, qr/^INSERT INTO/, 'a plain insert is untouched by the guard';
}

done_testing;
