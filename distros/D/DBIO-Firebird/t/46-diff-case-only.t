use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Diff;

# Offline (mock models): a name that differs between database and schema only
# in letter case is refused, never diffed (karr k41).
#
# Why it matters: DDL and Diff quote every identifier since k32. A database
# that an earlier version -- or anybody writing bare SQL -- created holds its
# objects upper-cased, because Firebird folds an unquoted name: ARTIST. The
# schema says `artist`, the target model therefore says "artist", and a diff
# that compares names exactly sees one table to drop and another to create.
# Applied, that is the table's rows gone. Same shape one level down: a column
# "NAME" against "name" is DROP + ADD, an index is DROP + CREATE.
#
# The rule sampled here, per object kind:
#
#   * a name only the database has and a name only the schema has, equal but
#     for case                                       -> die, no statement at all
#   * both spellings in the database, one of them in the schema too
#                                                    -> the other is plainly dropped
#   * both spellings in the schema, one of them in the database too
#                                                    -> the other is plainly new
#   * names that differ in more than case            -> DROP / CREATE as ever

my %int = (data_type => 'integer');

sub model {
  my (%m) = @_;
  return {
    tables       => { map { $_ => { table_name => $_, kind => 'table' } } @{ $m{tables} || [] } },
    columns      => $m{columns} || {},
    indexes      => $m{indexes} || {},
    foreign_keys => {},
  };
}

sub cols { [ map { { column_name => $_, %int } } @_ ] }
sub idx  { my ($name, @cols) = @_; ($name => { index_name => $name, is_unique => 0, columns => [@cols] }) }

# The SQL a diff renders, or undef and the error in $@.
sub sql_of {
  my ($source, $target) = @_;
  return eval { DBIO::Firebird::Diff->new(source => $source, target => $target)->as_sql };
}

# Every entry point that reaches the operations dies -- none of them renders or
# hands out a statement first -- and the error names both spellings.
sub refused_ok {
  my ($source, $target, $names, $what) = @_;

  for my $entry (qw/as_sql has_changes summary operations/) {
    my $diff = DBIO::Firebird::Diff->new(source => $source, target => $target);
    my $got  = eval { $diff->$entry; 1 };
    my $err  = "$@";
    ok(!$got, "$what: $entry dies") or diag "returned instead of dying: " . $diff->as_sql;
    like($err, $_, "$what: $entry names $_") for @$names;
  }
  return;
}

# --- table --------------------------------------------------------------------
{
  my $source = model(tables => ['ARTIST'], columns => { ARTIST => cols(qw/ARTISTID NAME/) });
  my $target = model(tables => ['artist'], columns => { artist => cols(qw/artistid name/) });

  refused_ok($source, $target, [ qr/table "ARTIST"/, qr/"artist"/ ], 'table, case only');

  my $err = eval { DBIO::Firebird::Diff->new(source => $source, target => $target)->as_sql; 1 } ? '' : $@;
  isa_ok($err, 'DBIO::Exception', 'the error');
  like("$err", qr/upper case/, '... says why the two spellings exist');
  like("$err", qr/table\('ARTIST'\)/, '... and offers the way that changes nothing: name it as stored');
  like("$err", qr/cannot rename a table/i, '... and the way through the database, as Firebird has it');
  unlike("$err", qr/ALTER COLUMN|DROP INDEX/, '... with no advice for kinds that are not in conflict');
}

# Both spellings are in the database and the schema keeps one: nothing is
# ambiguous, the other one is a table the schema no longer has.
is(
  sql_of(model(tables => [qw/ARTIST artist/]), model(tables => ['artist'])),
  'DROP TABLE "ARTIST";',
  'table: both spellings in the database, one in the schema -- the other is dropped',
) or diag $@;

# Both spellings are in the schema and the database has one: the other is new.
is(
  sql_of(
    model(tables => ['ARTIST']),
    model(tables => [qw/ARTIST artist/], columns => { artist => cols('id') }),
  ),
  qq{CREATE TABLE "artist" (\n  "id" integer\n);},
  'table: both spellings in the schema, one in the database -- the other is created',
) or diag $@;

# More than case: an unrelated table goes, an unrelated table comes.
is(
  sql_of(
    model(tables => ['OLD_ARTIST']),
    model(tables => ['artist'], columns => { artist => cols('id') }),
  ),
  qq{CREATE TABLE "artist" (\n  "id" integer\n);\nDROP TABLE "OLD_ARTIST";},
  'table: names that differ in more than case are created and dropped as before',
) or diag $@;

# --- column -------------------------------------------------------------------
{
  my $source = model(tables => ['cd'], columns => { cd => cols(qw/cdid TITLE/) });
  my $target = model(tables => ['cd'], columns => { cd => cols(qw/cdid title/) });

  refused_ok($source, $target, [ qr/column "TITLE"/, qr/"title"/, qr/table "cd"/ ], 'column, case only');

  my $err = sql_of($source, $target) // "$@";
  like($err, qr/ALTER TABLE "cd" ALTER COLUMN "TITLE" TO "title"/,
    'column: the error carries the rename statement Firebird has for it');
  unlike($err, qr/cannot rename a table|DROP INDEX/i, '... and no advice for the other kinds');
}

is(
  sql_of(
    model(tables => ['cd'], columns => { cd => cols(qw/cdid TITLE title/) }),
    model(tables => ['cd'], columns => { cd => cols(qw/cdid title/) }),
  ),
  'ALTER TABLE "cd" DROP "TITLE";',
  'column: both spellings in the database, one in the schema -- the other is dropped',
) or diag $@;

is(
  sql_of(
    model(tables => ['cd'], columns => { cd => cols(qw/cdid TITLE/) }),
    model(tables => ['cd'], columns => { cd => cols(qw/cdid TITLE title/) }),
  ),
  'ALTER TABLE "cd" ADD "title" integer;',
  'column: both spellings in the schema, one in the database -- the other is added',
) or diag $@;

is(
  sql_of(
    model(tables => ['cd'], columns => { cd => cols(qw/cdid OLD_TITLE/) }),
    model(tables => ['cd'], columns => { cd => cols(qw/cdid title/) }),
  ),
  qq{ALTER TABLE "cd" ADD "title" integer;\nALTER TABLE "cd" DROP "OLD_TITLE";},
  'column: names that differ in more than case are added and dropped as before',
) or diag $@;

# The same column name in two tables is two columns: "TITLE" leaving cd and
# "title" arriving in track have nothing to do with each other.
is(
  sql_of(
    model(tables => [qw/cd track/], columns => { cd => cols(qw/cdid TITLE/), track => cols('trackid') }),
    model(tables => [qw/cd track/], columns => { cd => cols('cdid'), track => cols(qw/trackid title/) }),
  ),
  qq{ALTER TABLE "cd" DROP "TITLE";\nALTER TABLE "track" ADD "title" integer;},
  'column: a case-only pair across two tables is not a pair',
) or diag $@;

# --- index --------------------------------------------------------------------
{
  my $source = model(tables => ['cd'], columns => { cd => cols('title') },
    indexes => { cd => { idx('CD_TITLE_IDX', 'title') } });
  my $target = model(tables => ['cd'], columns => { cd => cols('title') },
    indexes => { cd => { idx('cd_title_idx', 'title') } });

  refused_ok($source, $target,
    [ qr/index "CD_TITLE_IDX"/, qr/"cd_title_idx"/, qr/table "cd"/ ], 'index, case only');

  my $err = sql_of($source, $target) // "$@";
  like($err, qr/DROP INDEX "CD_TITLE_IDX"/, 'index: the error carries the statement that resolves it');
  unlike($err, qr/cannot rename a table|ALTER COLUMN/i, '... and no advice for the other kinds');
}

is(
  sql_of(
    model(tables => ['cd'], indexes => { cd => { idx('CD_TITLE_IDX', 'title'), idx('cd_title_idx', 'title') } }),
    model(tables => ['cd'], indexes => { cd => { idx('cd_title_idx', 'title') } }),
  ),
  'DROP INDEX "CD_TITLE_IDX";',
  'index: both spellings in the database, one in the schema -- the other is dropped',
) or diag $@;

is(
  sql_of(
    model(tables => ['cd'], indexes => { cd => { idx('CD_TITLE_IDX', 'title') } }),
    model(tables => ['cd'], indexes => { cd => { idx('CD_TITLE_IDX', 'title'), idx('cd_title_idx', 'title') } }),
  ),
  'CREATE INDEX "cd_title_idx" ON "cd" ("title");',
  'index: both spellings in the schema, one in the database -- the other is created',
) or diag $@;

is(
  sql_of(
    model(tables => ['cd'], indexes => { cd => { idx('OLD_IDX', 'title') } }),
    model(tables => ['cd'], indexes => { cd => { idx('cd_title_idx', 'title') } }),
  ),
  qq{DROP INDEX "OLD_IDX";\nCREATE INDEX "cd_title_idx" ON "cd" ("title");},
  'index: names that differ in more than case are created and dropped as before',
) or diag $@;

# A changed index is a DROP and a CREATE of ONE name. That pair is the same
# index, not a conflict -- and it must not make the new lower-case index beside
# it look like a respelling of the one being rebuilt.
is(
  sql_of(
    model(tables => ['cd'], indexes => { cd => { idx('CD_IDX', 'title') } }),
    model(tables => ['cd'], indexes => { cd => { idx('CD_IDX', 'title', 'year'), idx('cd_idx', 'title') } }),
  ),
  join("\n",
    'DROP INDEX "CD_IDX";',
    'CREATE INDEX "CD_IDX" ON "cd" ("title", "year");',
    'CREATE INDEX "cd_idx" ON "cd" ("title");',
  ),
  'index: a changed index is rebuilt under its own name, the other spelling beside it is new',
) or diag $@;

# --- everything at once -------------------------------------------------------
# One error for the whole diff: a user who fixes the first name and runs again
# only to meet the second has been told half of it.
{
  my $source = model(
    tables  => [qw/ARTIST TRACK cd/],
    columns => { ARTIST => cols('ARTISTID'), TRACK => cols('TRACKID'), cd => cols(qw/cdid TITLE YEAR/) },
    indexes => { cd => { idx('CD_TITLE_IDX', 'TITLE') } },
  );
  my $target = model(
    tables  => [qw/artist track cd/],
    columns => { artist => cols('artistid'), track => cols('trackid'), cd => cols(qw/cdid title year/) },
    indexes => { cd => { idx('cd_title_idx', 'title') } },
  );

  my $err = sql_of($source, $target) // "$@";
  like($err, $_, "all conflicts in one error: $_") for
    qr/table "ARTIST"/, qr/table "TRACK"/,
    qr/column "TITLE"/, qr/column "YEAR"/,
    qr/index "CD_TITLE_IDX"/;
  unlike($err, qr/column "ARTISTID"|column "TRACKID"/,
    '... the columns of a conflicting table are not listed again, the table is the conflict');
}

# A conflict beside ordinary changes: the ordinary changes are not rendered
# either. The diff is all or nothing -- half a migration script that silently
# leaves the conflicting table out would be read as the whole of it.
{
  my $source = model(tables => [qw/ARTIST gone/]);
  my $target = model(tables => [qw/artist new/], columns => { artist => cols('id'), new => cols('id') });

  my $sql = sql_of($source, $target);
  is($sql, undef, 'a conflict beside real changes: no statement is rendered, not even the unrelated ones')
    or diag $sql;
}

done_testing;
