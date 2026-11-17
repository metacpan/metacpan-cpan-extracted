use strict;
use warnings;
use utf8;
use Test::More;

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use DBIO::MySQL::Introspect;
use DBIO::MySQL::Diff;

# Every subtest works in a database of its own and registers its drop here, so
# that a subtest which dies still leaves nothing behind.
my @CLEANUP;
END {
  local ($@, $?);
  eval { $_->() } for @CLEANUP;
}

# LIVE half of karr k82 (t/117 has the offline half and the reasoning): the
# table that DBIO::MySQL::Deploy->upgrade creates in an empty database has the
# character set and collation install() gives it.
#
# WHY: the CREATE TABLE of a diff named the character set only, so the server
# filled in its own default collation (utf8mb4_0900_ai_ci on MySQL 8,
# utf8mb4_uca1400_ai_ci on MariaDB 11) while install_ddl writes
# utf8mb4_unicode_ci. Every text column of an upgraded table then differed from
# the schema, and each later diff reported a MODIFY COLUMN that changed nothing.
#
# What this file claims, for a table with text columns:
#   * the upgrade of the empty database runs;
#   * the text columns of the table carry utf8mb4_unicode_ci -- the server's
#     default is not what they end up with;
#   * the next diff is empty, and so is the diff of an install().
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/113).
subtest 'diff-create-table-collation' => sub {
  my $DB = "mysql_k82_$$";

  my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

  my $drop_database = sub { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") };
  push @CLEANUP, sub { if ($raw) { eval { $drop_database->() } } };

  unless (eval { $drop_database->(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
    my $why = "$@";
    undef $raw;
    plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
  }
  note sprintf 'server %s', scalar $raw->selectrow_array('SELECT VERSION()');

  my $version = 0;
  my $schema_version = sub {
    my $ns = 'K82Live::V' . ++$version;
    eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
    my $class = "${ns}::Result::Note";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table('note');
    $class->add_columns(
      id    => { data_type => 'integer', is_auto_increment => 1 },
      title => { data_type => 'varchar', size => 100 },
      body  => { data_type => 'text', is_nullable => 1 },
      code  => { data_type => 'char', size => 8 },
    );
    $class->set_primary_key('id');
    $ns->register_class(Note => $class);
    return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
  };

  my $collations = sub {
    return $raw->selectall_arrayref(
      'SELECT COLUMN_NAME, COLLATION_NAME FROM information_schema.COLUMNS '
    . 'WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLLATION_NAME IS NOT NULL ORDER BY COLUMN_NAME',
      undef, $DB, 'note');
  };

  my @WANT = (
    [ body => 'utf8mb4_unicode_ci' ], [ code => 'utf8mb4_unicode_ci' ], [ title => 'utf8mb4_unicode_ci' ],
  );

  my $next_diff_empty = sub {
    my ($schema, $name) = @_;
    my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
    ok $again && !$again->has_changes, $name
      or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";
  };

  # --- upgrade of an empty database --------------------------------------------
  {
    my $schema = $schema_version->();
    my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade };
    ok $diff && !$@, 'upgrade of the empty database runs' or diag $@;
    is_deeply $collations->(), \@WANT, 'the text columns of the table carry the collation of install_ddl';
    $next_diff_empty->($schema, 'the next diff has nothing left');
    $schema->storage->disconnect;
  }

  # --- install, for comparison -------------------------------------------------
  {
    $drop_database->();
    $raw->do("CREATE DATABASE `$DB`");
    my $schema = $schema_version->();
    ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'install runs' or diag $@;
    is_deeply $collations->(), \@WANT, '... with the same collations';
    $next_diff_empty->($schema, '... and the diff of it is empty');
    $schema->storage->disconnect;
  }
};

# LIVE half of karr k109 (subtest diff-table-collation of t/117-diff-collation.t has the offline half and the decision): a table
# that exists with another character set or collation than the schema gives it
# is converted by DBIO::MySQL::Deploy->upgrade where the data provably survives,
# and refused -- loudly, changing nothing -- where it does not.
#
# Before, a Result class with mysql_collate against such a table produced a
# MODIFY COLUMN per text column that wrote no collation: the table kept its
# collation and every later diff reported the same columns again.
#
# What this file claims, on whichever server DBIO_TEST_MYSQL_DSN names:
#   * within one character set (utf8mb4_bin -> utf8mb4_unicode_ci) the upgrade
#     is one CONVERT TO, the rows read back identical -- umlauts, CJK, emoji, the
#     bytes of a BLOB and a VARBINARY included -- and the next diff is empty;
#   * latin1 -> utf8mb4 converts with the same result (umlauts kept);
#   * a latin1 table with a TEXT column is refused (the server would promote the
#     type), and so is utf8mb4 -> latin1 (the emoji would be lost): a
#     DBIO::Exception naming table and both collations, the table, its collation
#     and its rows exactly as they were;
#   * a unique key whose values collide under the new collation is refused by the
#     server; the upgrade dies and the table is as it was.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/118).
subtest 'diff-table-collation' => sub {
  my $DB = "mysql_k109_$$";

  my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0, mysql_enable_utf8mb4 => 1 });

  my $drop_database = sub { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") };
  my $fresh_database = sub { $drop_database->(); $raw->do("CREATE DATABASE `$DB`") };
  push @CLEANUP, sub { if ($raw) { eval { $drop_database->() } } };

  unless (eval { $fresh_database->(); 1 }) {
    my $why = "$@";
    undef $raw;
    plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
  }
  note sprintf 'server %s', scalar $raw->selectrow_array('SELECT VERSION()');

  my $version = 0;
  my $schema_version = sub {
    my (%o) = @_;
    my $ns = 'K109Live::V' . ++$version;
    eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
    my $class = "${ns}::Result::Note";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table('note');
    $class->add_columns(
      id    => { data_type => 'integer', is_auto_increment => 1 },
      title => { data_type => 'varchar', size => 100 },
      body  => { data_type => ($o{body} // 'longtext'), is_nullable => 1 },
      raw   => { data_type => 'blob', is_nullable => 1 },
      code  => { data_type => 'varbinary', size => 16, is_nullable => 1 },
    );
    $class->set_primary_key('id');
    $class->add_unique_constraint([qw(title)]) if $o{unique};
    $class->mysql_charset($o{charset}) if $o{charset};
    $class->mysql_collate($o{collate}) if $o{collate};
    $ns->register_class(Note => $class);
    # MySQL reports in the language of the session; the test reads the English
    # "duplicate" of the server's error.
    return $ns->connect($dsn, $user, $pass, {
      on_connect_do => ["USE `$DB`", "SET SESSION lc_messages = 'en_US'"],
    });
  };

  # What the table holds, as perl sees it: characters for the text columns, hex for
  # the binary ones.
  my $rows = sub {
    return $raw->selectall_arrayref(
      "SELECT id, title, body, HEX(`raw`), HEX(`code`) FROM `$DB`.`note` ORDER BY id");
  };
  my $table_collation = sub {
    return scalar $raw->selectrow_array(
      'SELECT TABLE_COLLATION FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?', undef, $DB, 'note');
  };
  my $column_collations = sub {
    return $raw->selectall_arrayref(
      'SELECT COLUMN_NAME, COLLATION_NAME FROM information_schema.COLUMNS '
    . 'WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLLATION_NAME IS NOT NULL ORDER BY COLUMN_NAME',
      undef, $DB, 'note');
  };
  my $column_types = sub {
    return join ',', map { "$_->[0]:$_->[1]" } @{ $raw->selectall_arrayref(
      'SELECT COLUMN_NAME, DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? ORDER BY COLUMN_NAME',
      undef, $DB, 'note') };
  };

  my $next_diff_empty = sub {
    my ($schema, $name) = @_;
    my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
    ok $again && !$again->has_changes, $name
      or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";
  };

  my @ROWS = (
    [ 1, 'Müller',       '日本語 ñ ü ß straße', 'C3A4FF00', 'C3A4' ],
    [ 2, 'tête-à-tête',  'ÆØÅ',                  '00',       '01020304' ],
  );
  my @INSERT = ('INSERT INTO `note` (id, title, body, `raw`, `code`) VALUES (?, ?, ?, UNHEX(?), UNHEX(?))');
  my $fill = sub {
    my ($rows) = @_;
    $raw->do("USE `$DB`");
    $raw->do($INSERT[0], undef, @$_) for @$rows;
  };

  # --- same character set --------------------------------------------------------
  {
    $fresh_database->();
    my $old = $schema_version->(collate => 'utf8mb4_bin');
    DBIO::MySQL::Deploy->new(schema => $old)->install;
    $old->storage->disconnect;
    $fill->([ @ROWS, [ 3, 'emoji', '😀 und mehr', 'FF', '' ] ]);
    my @before = @{ $rows->() };
    is $table_collation->(), 'utf8mb4_bin', 'the table starts as utf8mb4_bin';

    my $new = $schema_version->(collate => 'utf8mb4_unicode_ci');
    my $diff = DBIO::MySQL::Deploy->new(schema => $new)->diff;
    is_deeply [ map { $_->as_sql } @{ $diff->operations } ],
      [ 'ALTER TABLE `note` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;' ],
      'the diff is one CONVERT TO';

    ok eval { DBIO::MySQL::Deploy->new(schema => $new)->upgrade; 1 }, 'the upgrade runs' or diag $@;
    is $table_collation->(), 'utf8mb4_unicode_ci', 'the table has the collation of the schema';
    is_deeply $column_collations->(), [ map { [ $_, 'utf8mb4_unicode_ci' ] } qw(body title) ], '... and so do its text columns';
    is_deeply $rows->(), \@before, 'every row reads back identical: text, emoji, BLOB and VARBINARY bytes';
    $next_diff_empty->($new, 'the next diff has nothing left');
    $new->storage->disconnect;
  }

  # --- latin1 -> utf8mb4 ------------------------------------------------------------
  {
    $fresh_database->();
    my $old = $schema_version->(charset => 'latin1', collate => 'latin1_swedish_ci');
    DBIO::MySQL::Deploy->new(schema => $old)->install;
    $old->storage->disconnect;
    $fill->([ [ 1, 'Müller', 'straße é à Æ', 'C3A4FF00', 'C3A4' ], [ 2, 'tête-à-tête', 'ÆØÅ', '00', '01020304' ] ]);
    my @before = @{ $rows->() };
    is $table_collation->(), 'latin1_swedish_ci', 'the table starts as latin1';
    my $types = $column_types->();

    my $new = $schema_version->();
    ok eval { DBIO::MySQL::Deploy->new(schema => $new)->upgrade; 1 }, 'the upgrade to utf8mb4 runs' or diag $@;
    is $table_collation->(), 'utf8mb4_unicode_ci', 'the table is utf8mb4_unicode_ci';
    is_deeply $rows->(), \@before, 'the umlauts and the binary columns are as they were';
    is $column_types->(), $types, 'no column changed its type';
    $next_diff_empty->($new, 'the next diff has nothing left');
    $new->storage->disconnect;
  }

  # --- refusals --------------------------------------------------------------------
  my $refused = sub {
    my (%o) = @_;
    $fresh_database->();
    my $old = $schema_version->(%{ $o{from} });
    DBIO::MySQL::Deploy->new(schema => $old)->install;
    $old->storage->disconnect;
    $fill->($o{rows});
    $raw->do($o{prep}) if $o{prep};
    my @before = @{ $rows->() };
    my ($collation, $types, $cols) = ($table_collation->(), $column_types->(), $column_collations->());

    my $new = $schema_version->(%{ $o{to} });
    my $diff = eval { DBIO::MySQL::Deploy->new(schema => $new)->upgrade };
    my $err = "$@";
    ok !$diff, "$o{name}: the upgrade dies";
    like $err, $o{error}, '... ' . $o{why};
    is $table_collation->(), $collation, '... the table has the collation it had';
    is $column_types->(), $types, '... its columns the types they had';
    is_deeply $column_collations->(), $cols, '... and the collations they had';
    is_deeply $rows->(), \@before, '... and the rows are as they were';
    $new->storage->disconnect;
  };

  $refused->(
    name => 'latin1 table with a TEXT column',
    from => { charset => 'latin1', collate => 'latin1_swedish_ci' },
    to   => {},
    prep => 'ALTER TABLE `note` MODIFY `body` text',
    rows => [ [ 1, 'Müller', 'straße', 'AA', 'BB' ] ],
    error => qr/table `note` has the collation latin1_swedish_ci and the target gives it utf8mb4_unicode_ci.*column `body` is a text and the server changes its type/s,
    why   => 'naming the table, both collations and the column',
  );
  $refused->(
    name => 'utf8mb4 to latin1 with an emoji in it',
    from => { collate => 'utf8mb4_unicode_ci' },
    to   => { charset => 'latin1', collate => 'latin1_swedish_ci' },
    rows => [ [ 1, 'Müller', '😀', 'AA', 'BB' ] ],
    error => qr/table `note` has the collation utf8mb4_unicode_ci and the target gives it latin1_swedish_ci.*may lose characters/s,
    why   => 'naming the table and both collations',
  );

  # A unique key that collides under the new collation: the server refuses.
  {
    $fresh_database->();
    my $old = $schema_version->(collate => 'utf8mb4_bin', unique => 1);
    DBIO::MySQL::Deploy->new(schema => $old)->install;
    $old->storage->disconnect;
    $fill->([ [ 1, 'abc', 'x', 'AA', 'BB' ], [ 2, 'ABC', 'y', 'AA', 'BB' ] ]);
    my @before = @{ $rows->() };

    my $new = $schema_version->(collate => 'utf8mb4_unicode_ci', unique => 1);
    ok !eval { DBIO::MySQL::Deploy->new(schema => $new)->upgrade; 1 }, 'a unique key that collides under the new collation: the upgrade dies';
    like "$@", qr/duplicate/i, '... with the server\'s duplicate-entry error';
    is $table_collation->(), 'utf8mb4_bin', '... the table keeps its collation';
    is_deeply $rows->(), \@before, '... and its rows';
    $new->storage->disconnect;
  }
};

# LIVE half of karr k111 (subtest diff-column-collation of t/117-diff-collation.t
# has the offline half and the reasoning): a column
# with a character set or collation of its own, off the default of its table, is
# written by MODIFY COLUMN, ADD COLUMN and CREATE TABLE, so the diff converges.
#
# The target is a second database, described by hand with the columns as they
# should be, and introspected like any target; the source is the database the
# upgrade runs on. After the statements ran, the introspection of the source reads
# the collations of the target and the next diff is empty.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in two databases of its own, created and dropped here (see subtest
# diff-table-collation).
subtest 'diff-column-collation' => sub {
  my @DB = ("mysql_k111_src_$$", "mysql_k111_tgt_$$");
  my ($src, $tgt);

  my $connect_to = sub {
    my ($db) = @_;
    return DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0, mysql_enable_utf8mb4 => 1 });
  };
  my $raw = $connect_to->();
  my $drop_databases = sub { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$_`") for @DB };
  push @CLEANUP, sub { if ($raw) { eval { $drop_databases->() } } };

  unless (eval { $drop_databases->(); $raw->do("CREATE DATABASE `$_`") for @DB; 1 }) {
    my $why = "$@";
    undef $raw;
    plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
  }
  note sprintf 'server %s', scalar $raw->selectrow_array('SELECT VERSION()');

  ($src, $tgt) = map { my $d = $connect_to->(); $d->do("USE `$_`"); $d } @DB;

  my $model = sub { return DBIO::MySQL::Introspect->new(dbh => $_[0])->model };
  my $diff_of = sub { return DBIO::MySQL::Diff->new(source => $model->($src), target => $model->($tgt)) };
  my $collations = sub {
    return $_[0]->selectall_arrayref(
      'SELECT COLUMN_NAME, COLLATION_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() '
    . 'AND TABLE_NAME = ? AND COLLATION_NAME IS NOT NULL ORDER BY COLUMN_NAME', undef, $_[1]);
  };

  # the source: a table on the default of the table; the target: columns off it
  $src->do('CREATE TABLE t (id int NOT NULL, title varchar(100) NOT NULL, tag varchar(20) NOT NULL, PRIMARY KEY (id)) '
    . 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
  $tgt->do('CREATE TABLE t (id int NOT NULL, title varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL, '
    . 'tag varchar(20) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL, '
    . 'note varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL, '
    . 'plain varchar(30) NOT NULL, PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
  $tgt->do('CREATE TABLE fresh (id int NOT NULL, name varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL, '
    . 'PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');

  my $diff = $diff_of->();
  my @sql = map { $_->as_sql } @{ $diff->operations };
  like join("\n", @sql), qr/MODIFY COLUMN `title` varchar\(100\) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL/, 'MODIFY writes the collation of the column';
  like join("\n", @sql), qr/ADD COLUMN `note` varchar\(30\) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL/, 'ADD COLUMN writes it';
  like join("\n", @sql), qr/`name` varchar\(30\) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL/, 'CREATE TABLE writes it';

  ok eval { $src->do($_) for @sql; 1 }, 'the statements run' or diag $@;
  is_deeply $collations->($src, 't'), $collations->($tgt, 't'), 'the columns have the collations of the target';
  is_deeply $collations->($src, 'fresh'), $collations->($tgt, 'fresh'), '... and so does the new table';

  my $again = $diff_of->();
  ok !$again->has_changes, 'the second diff is empty'
    or diag explain [ map { $_->as_sql } @{ $again->operations } ];

  # the other way: back onto the table default
  $src->do('ALTER TABLE t MODIFY COLUMN title varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL');
  $tgt->do('ALTER TABLE t MODIFY COLUMN title varchar(100) NOT NULL');
  my @back = map { $_->as_sql } @{ $diff_of->()->operations };
  is_deeply \@back, [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(100) NOT NULL;' ], 'a column back on the default is written without';
  $src->do($_) for @back;
  ok !$diff_of->()->has_changes, '... and the diff after it is empty';
};

done_testing;
