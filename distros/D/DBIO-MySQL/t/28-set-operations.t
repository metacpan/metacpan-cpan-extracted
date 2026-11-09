use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';
use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;

# karr #35 / core ADR 0039 -- _set_operation_keyword on this driver.
#
# The hook has two jobs: SPELL an operation, or REFUSE it. This driver has
# nothing to spell -- MySQL and MariaDB both use the ANSI keyword for every
# operation they have -- so what is pinned here is the refusal half, and above
# all its POLARITY: both availability declarations default to 1, because every
# non-EOL release of both products has all six operations and a default of 0
# would refuse four of them on the entire installed base.
#
# Fully offline, and necessarily so: ADR 0039 section 7 forbids the hook from
# asking the server which product or version it is, because
# DBIO::ResultSet::_set_operation bakes the keyword into the query while it is
# being built. Everything below therefore runs against a storage that never
# connects -- which is not a testing convenience but the contract itself.

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::MySQL::Storage',
);
my $storage = $schema->storage;

my %ansi = (
  union         => 'UNION',
  union_all     => 'UNION ALL',
  intersect     => 'INTERSECT',
  intersect_all => 'INTERSECT ALL',
  except        => 'EXCEPT',
  except_all    => 'EXCEPT ALL',
);

# --- 1. all six answer the ANSI keyword, unchanged ------------------------
#
# The override refuses; it never renames. MariaDB's MINUS synonym needs
# sql_mode=ORACLE, which DBIO never sets, and EXCEPT keeps working under it
# anyway -- so there is no second spelling on either product and core's base
# map is the whole answer here.

is $storage->_set_operation_keyword($_), $ansi{$_},
  "_set_operation_keyword('$_') is the ANSI $ansi{$_}, not re-spelled"
    for sort keys %ansi;

# --- 2. the two availability declarations, and their polarity -------------

is $storage->_use_set_operator_intersect_except, 1,
  'INTERSECT / EXCEPT declared available by default';
is $storage->_use_set_operator_all_family, 1,
  'INTERSECT ALL / EXCEPT ALL declared available by default';

# The polarity is the decision this ticket made, so it gets its own assertion
# rather than riding on the two above: dbio-oracle declares the identically
# named _use_set_operator_all_family as 0, because Oracle's long-term releases
# are the ones WITHOUT the family. Here every supported release of both
# products is past every boundary (MySQL 8.0.31+/8.4/9.x, MariaDB 10.5+), so a
# default of 0 would withhold four working operations from essentially every
# server this driver meets.
lives_ok { $storage->_set_operation_keyword($_) for sort keys %ansi }
  'out of the box this driver refuses nothing -- no version of either product '
. 'lacks an operation on ALL its releases, so there is nothing to refuse '
. 'unconditionally';

# Which operations a server has is a fact about the SERVER, not about the DBD,
# so it must hold for a dbi:MariaDB: connection too -- by inheritance rather
# than a second declaration (karr #28: the subclass is the DBD::MariaDB
# binding and nothing else).
{
  my $mariadb_schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::MySQL::Storage::MariaDB',
  );
  my $mariadb_storage = $mariadb_schema->storage;

  is $mariadb_storage->_use_set_operator_intersect_except, 1,
    'the DBD::MariaDB subclass inherits the INTERSECT/EXCEPT declaration';
  is $mariadb_storage->_use_set_operator_all_family, 1,
    '... and the ALL-family one';

  ok ! DBIO::MySQL::Storage::MariaDB->can('_set_operation_keyword')
     || DBIO::MySQL::Storage::MariaDB->can('_set_operation_keyword')
          == DBIO::MySQL::Storage->can('_set_operation_keyword'),
    '... and does not override the hook itself';
}

# --- 3. the declarations sit in the DETERMINATION tier, not the force slot -
#
# _use_X is the CALLER's force slot, and this driver's answer is the
# PERMISSIVE one -- core's default is the restrictive 0 -- so the 1 has to
# be the fallback a cleared force lands back on; the round-trip below is
# that contract. It works because the two slots are physically separate:
# set_inherited writes the instance hash for an instance invocant and the
# package variable for a class one, so a force never overwrites the class
# declaration. Clearing works because of the core karr #137 fix --
# get_inherited used to read the instance with exists() rather than
# defined(), leaving a tombstone that shadowed the declaration for the life
# of the storage; both forms now measure 1 / 0 / 1. The 1 lives in the
# determination tier because displacing a permissive answer would silently
# turn four working operations off.

{
  my $roundtrip = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::MySQL::Storage',
  )->storage;

  is $roundtrip->_use_set_operator_all_family, 1, 'fresh: the driver answers 1';

  $roundtrip->_use_set_operator_all_family(0);
  is $roundtrip->_use_set_operator_all_family, 0, 'forced off: the caller wins';

  $roundtrip->_use_set_operator_all_family(undef);
  is $roundtrip->_use_set_operator_all_family, 1,
    'force cleared: the question goes back to the DRIVER\'s 1, not to core\'s '
  . 'default 0 -- clearing the force returns the question to the determination '
  . 'tier, where this driver\'s permissive answer lives (core karr #137)';
}

# --- 4. refusing the ALL family only ---------------------------------------
#
# MariaDB 10.3 / 10.4 is the real deployment this expresses: it has EXCEPT and
# INTERSECT (10.3, MDEV-10141) but not their ALL forms (10.5.0, MDEV-18844).
# One flag could not have said that, which is why there are two.

{
  my $old = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::MySQL::Storage',
  );
  my $old_storage = $old->storage;
  $old_storage->_use_set_operator_all_family(0);
  $old_storage->reset_captured;

  for my $op (qw( except_all intersect_all )) {
    throws_ok { $old_storage->_set_operation_keyword($op) }
      qr/\QThis server has no INTERSECT ALL \/ EXCEPT ALL\E/,
      "$op is refused";

    throws_ok { $old_storage->_set_operation_keyword($op) }
      'DBIO::Exception',
      "... as a typed DBIO exception (F21), not a bare croak";
  }

  # The message has to carry BOTH products' boundaries, because the hook is
  # forbidden from knowing which one it is talking to. A message naming only
  # one of them would be wrong half the time.
  throws_ok { $old_storage->_set_operation_keyword('except_all') }
    qr/MySQL.*8\.0\.31.*MariaDB.*10\.5\.0/s,
    '... and names both products\' boundaries, since it cannot know which '
  . 'server it is refusing for';

  # ADR 0039 section 3: except is NOT a fallback for except_all -- it collapses
  # duplicates, so substituting it silently returns a different set. The
  # message says so rather than pointing at it as an alternative.
  throws_ok { $old_storage->_set_operation_keyword('except_all') }
    qr/collapses duplicates/,
    '... and says why the adjacent operation is not a fallback';

  # The four that are unaffected stay unaffected.
  is $old_storage->_set_operation_keyword($_), $ansi{$_},
    "$_ is untouched by the ALL-family refusal"
      for qw( union union_all intersect except );
}

# --- 5. refusing INTERSECT / EXCEPT entirely -------------------------------
#
# MySQL < 8.0.31 and MariaDB < 10.3. The outer switch subsumes the inner one:
# an engine without EXCEPT has no EXCEPT ALL either, so all four refuse even
# though the ALL-family declaration is still 1.

{
  my $ancient = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::MySQL::Storage',
  )->storage;
  $ancient->_use_set_operator_intersect_except(0);

  is $ancient->_use_set_operator_all_family, 1,
    'the ALL-family declaration is left alone ...';

  for my $op (qw( except except_all intersect intersect_all )) {
    throws_ok { $ancient->_set_operation_keyword($op) }
      qr/\QThis server has no INTERSECT \/ EXCEPT\E/,
      "... yet $op refuses on the outer boundary, which subsumes it";
  }

  throws_ok { $ancient->_set_operation_keyword('except') }
    qr/MySQL.*8\.0\.31.*MariaDB.*10\.3/s,
    'the outer refusal names both products\' boundaries too';

  # UNION and UNION ALL predate anything this driver can meet, on either
  # product, so no switch reaches them and the message points at them.
  is $ancient->_set_operation_keyword($_), $ansi{$_},
    "$_ survives every refusal -- it predates both products' version range"
      for qw( union union_all );

  throws_ok { $ancient->_set_operation_keyword('except') }
    qr/\$rs->union/,
    '... which is what the message offers instead';
}

# --- 6. the timing contract: a refused operation issues NO SQL -------------
#
# ADR 0039 section 4. The keyword is resolved as _set_operation's first
# statement, before a single operand is rendered, so a refusing engine throws
# at query-BUILD time and never hands back a fragment that could be embedded
# in a larger query.

{
  my $refusing = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::MySQL::Storage',
  );
  my $refusing_storage = $refusing->storage;
  $refusing_storage->_use_set_operator_all_family(0);
  $refusing_storage->reset_captured;

  my $rs = $refusing->resultset('Artist')
    ->search(undef, { columns => [qw( artistid name )] });

  throws_ok { $rs->except_all($rs) }
    qr/\QThis server has no INTERSECT ALL \/ EXCEPT ALL\E/,
    'the refusal reaches the caller through $rs->except_all itself';

  is scalar($refusing_storage->captured_queries), 0,
    '... and the refused operation issued no SQL at all -- it threw while the '
  . 'query was being built, so nothing half-assembled escaped';

  # And the operations this server does have are untouched by the refusal.
  is_same_sql_bind(
    $rs->except($rs)->as_query,
    '(SELECT `me`.`artistid`, `me`.`name` FROM ('
      . 'SELECT `me`.`artistid`, `me`.`name` FROM `artist` `me`'
      . ' EXCEPT '
      . 'SELECT `me`.`artistid`, `me`.`name` FROM `artist` `me`) `me`)',
    [],
    'refusing except_all leaves except itself rendering, backtick-quoted',
  );

  is scalar($refusing_storage->captured_queries), 0,
    '... and building that one connected to nothing either';
}

# --- 7. end to end, no refusal: the ANSI keyword reaches the SQL -----------

{
  $storage->reset_captured;

  my $rs = $schema->resultset('Artist')
    ->search(undef, { columns => [qw( artistid name )] });

  for my $op (sort keys %ansi) {
    like ${ $rs->$op($rs)->as_query }->[0], qr/\Q $ansi{$op} \E/,
      "\$rs->$op renders $ansi{$op} on an unrestricted deployment";
  }

  is scalar($storage->captured_queries), 0,
    'and none of the six opened a connection to choose its keyword';
}

# --- 8. what this driver hands back to core --------------------------------
#
# An unknown $op is a CORE programming error, not an engine fact: this driver
# names only the four operations it has an opinion about and delegates the
# rest, so a typo lands on core's throw rather than becoming a bare token in
# the SQL. The undef case is why the hook opens with a `defined` guard -- core
# handles undef, but only if the override passes it down without warning on
# the way.

throws_ok { $storage->_set_operation_keyword('symmetric_difference') }
  qr/Unknown set operation 'symmetric_difference'/,
  'an unknown operation reaches core\'s throw, not a driver-invented answer';

{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  throws_ok { $storage->_set_operation_keyword(undef) }
    qr/Unknown set operation '\(undef\)'/,
    'an undefined operation reaches core\'s throw too';

  is_deeply \@warnings, [],
    '... without an uninitialized-value warning on the way -- the `defined` '
  . 'guard is the first statement of the override, not decoration';
}

throws_ok { $storage->_set_operation_keyword('EXCEPT') }
  qr/Unknown set operation 'EXCEPT'/,
  'the hook takes the canonical op name, never the rendered keyword';

done_testing;
