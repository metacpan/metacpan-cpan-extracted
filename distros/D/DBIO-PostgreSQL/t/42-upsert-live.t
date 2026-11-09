use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;

# DBIO::Test::Schema keeps no driver in its class: this file runs it on
# PostgreSQL (core ADR 0067).
DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

# ADR 0036 -- atomic upsert round-trips against a real PostgreSQL. The
# statement shapes and the capability gate are pinned offline in
# t/41-upsert-on-conflict.t; this file only asks the engine what actually
# happened to the data.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/};

plan skip_all => <<'EOM' unless $dsn && $user;
Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test
( NOTE: This test drops and creates a table called 'dbio_upsert_test' )
EOM

# A server that is not there fails the file, with a plan (karr k113).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

BEGIN {
  package DBIO::Test::Schema::UpsertTest;
  push @main::test_classes, __PACKAGE__;

  use strict;
  use warnings;
  use base 'DBIO::Test::BaseResult';

  __PACKAGE__->table('dbio_upsert_test');
  __PACKAGE__->add_columns(
    id => {
      data_type         => 'integer',
      is_auto_increment => 1
    },
    name => {
      data_type => 'varchar',
      size      => 100
    },
    email => {
      data_type   => 'varchar',
      size        => 100,
      is_nullable => 1
    },
    score => {
      data_type     => 'integer',
      default_value => 0
    }
  );
  __PACKAGE__->set_primary_key('id');

  # key => $name renders the columns core resolved the name to, never
  # ON CONSTRAINT $name -- so the DBIO-side name is free to be pure client
  # metadata. The first two happen to match the DDL below, the third
  # deliberately does not name anything PostgreSQL knows.
  __PACKAGE__->add_unique_constraint(dbio_upsert_test_name_key  => ['name']);
  __PACKAGE__->add_unique_constraint(dbio_upsert_test_email_key => ['email']);
  __PACKAGE__->add_unique_constraint(client_side_only           => ['name']);
}

our @test_classes;
DBIO::Test::Schema->load_classes( map { s/.+:://; $_ } @test_classes );

my $schema = DBIO::Test::Schema->connect($dsn, $user, $pass, { AutoCommit => 1 });

plan skip_all => 'PostgreSQL 9.5 or newer required for INSERT ... ON CONFLICT'
  unless $schema->storage->_server_info->{normalized_dbms_version} >= 9.005;

ok $schema->storage->_use_supports_upsert,
  'the driver declares supports_upsert against this server';

my $dbh = $schema->storage->dbh;
$dbh->do('DROP TABLE IF EXISTS dbio_upsert_test');
$dbh->do(q{
  CREATE TABLE dbio_upsert_test (
    id     serial       NOT NULL,
    name   varchar(100) NOT NULL,
    email  varchar(100),
    score  integer      NOT NULL DEFAULT 0,
    CONSTRAINT dbio_upsert_test_pkey       PRIMARY KEY (id),
    CONSTRAINT dbio_upsert_test_name_key   UNIQUE (name),
    CONSTRAINT dbio_upsert_test_email_key  UNIQUE (email)
  )
}, { RaiseError => 1 });

END {
  eval { $dbh->do('DROP TABLE IF EXISTS dbio_upsert_test') } if $dbh;
}

my $rs = $schema->resultset('UpsertTest');

# ---------------------------------------------------------------------------
# insert path and update path -- same call, same conflict target
# ---------------------------------------------------------------------------

my $inserted = $rs->upsert(
  { name => 'alpha', email => 'alpha@example.com', score => 1 },
  { conflict_target => ['name'] }
);

ok $inserted, 'upsert on an empty table returns a row';
ok $inserted->id, '... with the id the engine assigned';
is $inserted->score, 1, '... and the inserted values';
is $rs->count, 1, '... exactly one row exists';

my $updated = $rs->upsert(
  { name => 'alpha', email => 'alpha@example.com', score => 2 },
  { conflict_target => ['name'] }
);

is $updated->id, $inserted->id,
  'the second upsert wrote the SAME row -- update, not insert';
is $rs->count, 1, '... no second row appeared';
is $rs->find($inserted->id)->score, 2,
  '... and the attempted value was written (EXCLUDED)';

# ---------------------------------------------------------------------------
# a restricted update set, and a literal expression over the stored value
# ---------------------------------------------------------------------------

$rs->upsert(
  { name => 'alpha', email => 'changed@example.com', score => 99 },
  { conflict_target => ['name'], update => ['score'] }
);

{
  my $row = $rs->find($inserted->id);
  is $row->score, 99, 'update => [cols] writes the listed column';
  is $row->email, 'alpha@example.com',
    '... and leaves the unlisted one alone';
}

$rs->upsert(
  { name => 'alpha', score => 0 },
  {
    conflict_target => ['name'],
    update          => { score => \'dbio_upsert_test.score + 1' }
  }
);

is $rs->find($inserted->id)->score, 100,
  'a caller literal reads the stored value, not the attempted one';

# A plain value in the update set is written as the value it is (karr k122) --
# the statement binds it, by the bindtype of the driver's maker. Next to a
# condition with a bind of its own, which has to land in its place too.
$rs->upsert(
  { name => 'alpha', score => 0 },
  { conflict_target => ['name'], update => { email => 'plain@example.com' } }
);

{
  my $row = $rs->find($inserted->id);
  is $row->email, 'plain@example.com',
    'update => { col => $plain_value } writes that value';
  is $row->score, 100, '... and no other column';
}

$rs->upsert(
  { name => 'alpha', score => 0 },
  {
    conflict_target => ['name'],
    update          => { email => 'guarded@example.com', score => 101 },
    result          => 'void',
    update_where    => { score => { '<' => 100 } },
  }
);

is $rs->find($inserted->id)->email, 'plain@example.com',
  'a plain-value update whose condition does not hold writes nothing';

$rs->upsert(
  { name => 'alpha', score => 0 },
  {
    conflict_target => ['name'],
    update          => { email => 'guarded@example.com', score => 101 },
    result          => 'void',
    update_where    => { score => { '<' => 1000 } },
  }
);

{
  my $row = $rs->find($inserted->id);
  is $row->email, 'guarded@example.com',
    '... and one whose condition holds writes the plain values';
  is $row->score, 101, '... an integer one among them';
}

# ---------------------------------------------------------------------------
# the named-constraint form
# ---------------------------------------------------------------------------

$rs->upsert(
  { name => 'alpha', email => 'alpha@example.com', score => 7 },
  { key => 'dbio_upsert_test_name_key' }
);

is $rs->find($inserted->id)->score, 7,
  'key => $constraint targets the same conflict as its column list does';

# The two names no server-side constraint answers to. Both would be
# "constraint ... for table ... does not exist" if the name were rendered.
$rs->upsert(
  { name => 'alpha', email => 'alpha@example.com', score => 11 },
  { key => 'client_side_only' }
);

is $rs->find($inserted->id)->score, 11,
  'a DBIO constraint name that exists in no database still upserts';

$rs->upsert(
  { id => $inserted->id, name => 'alpha', score => 12 },
  { key => 'primary' }
);

is $rs->find($inserted->id)->score, 12,
  "key => 'primary' upserts -- no PostgreSQL database has that constraint name";

# ---------------------------------------------------------------------------
# DO NOTHING
# ---------------------------------------------------------------------------

{
  my $nothing = $rs->upsert(
    { name => 'alpha', email => 'alpha@example.com', score => 4242 },
    { conflict_target => 'any', on_conflict => 'nothing',
      result => 'row_or_undef' }
  );

  is $nothing, undef, 'DO NOTHING on a conflicting row returns undef';
  is $rs->find($inserted->id)->score, 12, '... and wrote nothing';
}

{
  my $fresh = $rs->upsert(
    { name => 'beta', email => 'beta@example.com', score => 5 },
    { conflict_target => 'any', on_conflict => 'nothing',
      result => 'row_or_undef' }
  );

  ok $fresh, 'DO NOTHING with no conflict inserts and returns the row';
  is $fresh->score, 5, '... with the inserted values';
  is $rs->count, 2, '... two rows now';
}

# ---------------------------------------------------------------------------
# result shapes that spend nothing on identity
# ---------------------------------------------------------------------------

# Both are called in scalar context on purpose: result => 'void' returns an
# empty list, which would silently eat an argument of a list-context is().
my $count = $rs->upsert(
  { name => 'beta', email => 'beta@example.com', score => 6 },
  { conflict_target => ['name'], result => 'count' }
);
is $count, 1, "result => 'count' returns the affected-row count";

my $void = $rs->upsert(
  { name => 'beta', email => 'beta@example.com', score => 8 },
  { conflict_target => ['name'], result => 'void' }
);
is $void, undef, "result => 'void' returns nothing";

is $rs->search({ name => 'beta' })->single->score, 8,
  '... but still wrote the row';

# ---------------------------------------------------------------------------
# a conflict the statement did not arbitrate on is an error, not a silent
# rewrite of somebody else's row (ADR 0036 section 1, worked example)
# ---------------------------------------------------------------------------

throws_ok {
  $rs->upsert(
    { name => 'gamma', email => 'beta@example.com', score => 1 },
    { conflict_target => ['name'] }
  );
} qr/dbio_upsert_test_email_key|duplicate key/,
  'a collision outside the named conflict target raises the unique violation';

is $rs->count, 2, '... and nothing was written';

# ---------------------------------------------------------------------------
# what this engine refuses before it ever reaches the server
# ---------------------------------------------------------------------------

throws_ok {
  $rs->upsert(
    { name => 'alpha', score => 1 },
    { conflict_target => 'any' }
  );
} qr/DO UPDATE requires the arbiter index to be named/,
  "conflict_target => 'any' with DO UPDATE throws on PostgreSQL";

# ---------------------------------------------------------------------------
# the conditional conflict branch -- the last-write-wins guard (ADR 0036
# section 1, core k105)
#
# This is the part that only a real engine can answer. Offline the statement
# looks right whether or not the condition bites; here the question is whether
# an older write is actually SUPPRESSED, and what comes back when it is.
# ---------------------------------------------------------------------------

ok $schema->storage->_use_supports_upsert_where,
  'the driver declares supports_upsert_where against this server';

my $guarded = $rs->upsert(
  { name => 'delta', email => 'delta@example.com', score => 50 },
  { conflict_target => ['name'] }
);

is $guarded->score, 50, 'the guarded row starts out at 50';

# score stands in for a version/timestamp: write only where the value that was
# attempted is newer (higher) than the one already stored. The unqualified
# column is the STORED row, { -attempted => ... } the row the statement tried
# to insert -- both sayable without an engine token.
my %guard = ( score => { '<' => { -attempted => 'score' } } );

{
  my $stale = $rs->upsert(
    { name => 'delta', email => 'delta@example.com', score => 40 },
    { conflict_target => ['name'], update_where => \%guard,
      result => 'row_or_undef' }
  );

  is $stale, undef,
    'an older write is suppressed -- no row written, so row_or_undef is undef';
  is $rs->find($guarded->id)->score, 50,
    '... and the newer stored value survived the older write';
}

{
  my $newer = $rs->upsert(
    { name => 'delta', email => 'delta@example.com', score => 60 },
    { conflict_target => ['name'], update_where => \%guard,
      result => 'row_or_undef' }
  );

  ok $newer, 'a newer write passes the condition and returns the row';
  is $newer->id, $guarded->id, '... the same row -- an update, not an insert';
  is $newer->score, 60, '... carrying the attempted value';
}

is $rs->count, 3, 'the guard never inserted a second delta';

# Called in scalar context on purpose (see the result-shape section above).
my $suppressed = $rs->upsert(
  { name => 'delta', email => 'delta@example.com', score => 1 },
  { conflict_target => ['name'], update_where => \%guard, result => 'count' }
);
is $suppressed, 0,
  "result => 'count' reports zero rows for a write the condition suppressed";

# The marker has to survive at depth -- in the set list it is only ever a
# top-level value, here it sits inside a nested -or.
$rs->upsert(
  { name => 'delta', email => 'delta@example.com', score => 70 },
  {
    conflict_target => ['name'],
    update_where    => { -and => [
      \%guard,
      { -or => [
        { email => undef },
        { email => { -attempted => 'email' } }
      ] }
    ] },
    result => 'void'
  }
);

is $rs->search({ name => 'delta' })->single->score, 70,
  'a nested condition with -attempted at depth is evaluated by the engine';

# The escape hatch: engine SQL written knowingly, for what the abstract form
# cannot say.
$rs->upsert(
  { name => 'delta', email => 'delta@example.com', score => 80 },
  {
    conflict_target => ['name'],
    update_where    => \'excluded.score > dbio_upsert_test.score',
    result          => 'void'
  }
);

is $rs->search({ name => 'delta' })->single->score, 80,
  'a literal condition passes through to the engine unchanged';

$rs->upsert(
  { name => 'delta', email => 'delta@example.com', score => 80 },
  {
    conflict_target => ['name'],
    update_where    => \[ 'excluded.score > dbio_upsert_test.score + ?', 5 ],
    result          => 'void'
  }
);

is $rs->search({ name => 'delta' })->single->score, 80,
  '... and a literal with bind values binds in the right position';

# A conflicting row the condition rejects is not an error -- the statement
# succeeded, it simply wrote nothing. An insert that never conflicts is not
# affected by the condition at all.
{
  my $fresh = $rs->upsert(
    { name => 'epsilon', email => 'epsilon@example.com', score => 1 },
    { conflict_target => ['name'], update_where => \%guard,
      result => 'row_or_undef' }
  );

  ok $fresh, 'a non-conflicting insert is not touched by the condition';
  is $fresh->score, 1, '... and stores what was asked for';
  is $rs->count, 4, '... as a new row';
}

done_testing;
