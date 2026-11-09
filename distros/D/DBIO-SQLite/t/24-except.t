use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::SQLite::Test;
use DBIO::Test::Schema;
use DBIO::SQLite::Storage;
use DBIO::Storage::DBI;

# ADR 0037 gave set difference a storage hook, _except_operator, so that
# ResultSet::except stopped comparing sqlt_type to 'Oracle' -- a driver-name
# match that reached $dbh->{Driver}{Name} through _get_dbh, so
# $rs->except($other)->as_query opened a database connection at query-build time
# purely to choose a word.
#
# ADR 0039 replaced that hook with _set_operation_keyword($op), one seam for all
# six set operations, asked with the canonical operation name. The hook has two
# jobs: SPELL the operation for this engine, or REFUSE it where the engine does
# not have it. SQLite needs the second: its compound operators are UNION, UNION
# ALL, INTERSECT and EXCEPT -- ALL attaches to UNION alone -- so intersect_all
# and except_all have no spelling here at all (karr k30).
#
# This file used to assert that the driver did NOT override _except_operator.
# After the rename that assertion was vacuous: no such name exists anywhere any
# more, so it could not fail while still claiming something. It is retargeted
# here, and its claim has changed with the code -- the driver DOES override the
# hook now, and what has to be pinned instead is that the override refuses only
# the two operations SQLite lacks and re-spells nothing: the other four are
# handed to next::method and come back with core's base keyword.

my $schema  = DBIO::SQLite::Test->init_schema;
my $storage = $schema->storage;
my $cd_rs   = $schema->resultset('CD');

# ------------------------------------------------------- the four it does have

my %ansi = (
  union         => 'UNION',
  union_all     => 'UNION ALL',
  intersect     => 'INTERSECT',
  except        => 'EXCEPT',
);

is (
  $storage->_set_operation_keyword($_),
  $ansi{$_},
  "$_ is spelled $ansi{$_} here -- SQLite has this compound operator and "
. 'speaks the ANSI keyword, so the driver adds nothing',
) for sort keys %ansi;

isnt (
  DBIO::SQLite::Storage->can('_set_operation_keyword'),
  DBIO::Storage::DBI->can('_set_operation_keyword'),
  'the driver does override the hook (it has to -- two of the six operations '
. 'do not exist on this engine), which is why "spelled by the base" above '
. 'cannot be taken on trust from the class hierarchy',
);

is (
  $storage->_set_operation_keyword('except'),
  DBIO::Storage::DBI->can('_set_operation_keyword')->($storage, 'except'),
  '... and EXCEPT really is core\'s base answer reached through next::method, '
. 'not a keyword the override happens to repeat: dbio-oracle re-spells this '
. 'one MINUS, SQLite does not re-spell it at all',
);

throws_ok
  { $storage->_set_operation_keyword('no_such_operation') }
  qr/\QUnknown set operation 'no_such_operation'\E/,
  'an unrecognised operation still reaches core\'s base and is refused there '
. 'as the programming error it is -- proof the override hands on what it has '
. 'no opinion about instead of swallowing it',
;

# ------------------------------------------------------- the two it does not

for my $case (
  [ intersect_all => 'INTERSECT ALL', 'intersect' ],
  [ except_all    => 'EXCEPT ALL',    'except'    ],
) {
  my ($op, $keyword, $nearest) = @$case;
  my $hint = "\$rs->$nearest";

  throws_ok
    { $storage->_set_operation_keyword($op) }
    qr/\QSQLite has no $keyword operator\E/,
    "$op is refused rather than spelled: SQLite would answer core's "
  . "inherited $keyword with a syntax error several layers below the method "
  . 'the caller called',
  ;

  throws_ok
    { $storage->_set_operation_keyword($op) }
    qr/\bunconditional\b/,
    '... and the message says the refusal is unconditional, which here is a '
  . 'sourced engine fact and not ADR 0039 section 7\'s trade: the four '
  . 'compound operators arrived together before SQLite 1.0 and none has been '
  . 'added since, so no version is being withheld from',
  ;

  throws_ok
    { $storage->_set_operation_keyword($op) }
    qr/\Q$hint\E/,
    "... and it names \$rs->$nearest as the nearest operation this engine "
  . 'does have while saying it is not a drop-in -- the substitution removes '
  . 'duplicates, so the caller makes it deliberately or not at all',
  ;
}

# ------------------------------- rendered, and refused, without a connection

{
  my $cold         = DBIO::Test::Schema->clone;
  $cold->storage_type('DBIO::SQLite::Storage');
  $cold            = $cold->connect('dbi:SQLite::memory:');
  my $cold_storage = $cold->storage;

  my $rs    = $cold->resultset('CD')->search({ year => 1999 });
  my $other = $cold->resultset('CD')->search({ year => 2001 });

  my ($sql) = @{ ${ $rs->except($other)->as_query } };

  like (
    $sql,
    qr/\bEXCEPT\b/,
    'except joins its two operands with the keyword the storage named',
  );

  unlike ($sql, qr/\bMINUS\b/, '... and not with Oracle\'s spelling');

  is (
    ref $cold_storage,
    'DBIO::SQLite::Storage',
    'the declared driver is the storage before any connection (core ADR '
  . '0067: a schema always has a driver, none is found from the DSN), so the '
  . 'keyword is this driver\'s answer and not the base default arrived at by '
  . 'accident',
  );

  throws_ok
    { $rs->except_all($other) }
    qr/\QSQLite has no EXCEPT ALL operator\E/,
    'and the refusal fires at query-BUILD time, from the ResultSet method '
  . 'itself: _set_operation resolves the keyword before it renders a single '
  . 'operand, so a refused operation never hands back a fragment that could '
  . 'be embedded in a larger query (ADR 0039 section 4)',
  ;

  ok (
    ! $cold_storage->connected,
    '... and neither the rendering nor the refusal opened a connection: the '
  . 'keyword is a static class fact, not a sqlt_type lookup through _get_dbh, '
  . 'and a hook that connected in order to throw would be the worst of both '
  . '(ADR 0039 section 7)',
  );
}

# ------------------------------------------------------------- live round-trip

{
  # The rendering above only proves the word reaches the SQL. That SQLite
  # *executes* it is the other half of "no override needed", so the difference
  # is taken against the engine and compared with the same difference taken in
  # Perl over the two operand queries.
  my $all = $cd_rs->search(undef,                      { columns => ['cdid'] })->hri;
  my $old = $cd_rs->search({ year => { '<' => 2000 } }, { columns => ['cdid'] })->hri;

  my %subtracted = map { $_->{cdid} => 1 } $old->all;
  my @expected   = sort { $a <=> $b }
                   grep { ! $subtracted{$_} }
                   map  { $_->{cdid} } $all->all;

  ok (
    @expected && @expected < $cd_rs->count,
    'the operands are chosen so the difference is neither empty nor the whole '
  . 'set -- an EXCEPT that degraded to a union, or that dropped its right '
  . 'operand, would answer one of those and go unnoticed otherwise',
  );

  my @got = sort { $a <=> $b } map { $_->{cdid} } $all->except($old)->all;

  is_deeply (
    \@got,
    \@expected,
    'EXCEPT round-trips against the engine: the rows of the left operand that '
  . 'the right one does not have, and only those',
  );
}

done_testing;
