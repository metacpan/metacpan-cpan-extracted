use strict;
use warnings;
use Test::More;

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use DBIO::MySQL::DDL;

# Every subtest works in a database of its own and registers its drop here, so
# that a subtest which dies still leaves nothing behind.
my @CLEANUP;
END {
  local ($@, $?);
  eval { $_->() } for @CLEANUP;
}

# LIVE half of karr k79 (t/121 has the offline half and the reasoning): the
# views of a schema are created, replaced and dropped as views, and the next
# diff has nothing left.
#
# WHY IT NEEDS A SERVER. The server does not keep a view as written: the
# definition in information_schema.views is rewritten (backticks, AS for every
# column, parentheses, its own spelling) and the name of the DATABASE is put in
# front of every table. The target of an upgrade is a temporary database, so
# the same view reads differently there and in the live one unless the
# introspection takes its own database name out. This file is the measurement
# that the comparison holds on this server, MySQL and MariaDB alike.
#
# What the file claims, in a database of its own:
#   1. install makes the views, and the diff right after has nothing to say;
#   2. an upgrade that changes a view, adds one over a new table, and adds a
#      column to the table the changed view reads: the changed view is dropped
#      first and created again last, the new view comes after the new table,
#      no TABLE statement is written for any view, and the views answer with
#      what their new definition selects;
#   3. the diff after it is empty, and a second upgrade does nothing;
#   4. an upgrade to a schema without views drops them with DROP VIEW (the
#      server refuses DROP TABLE on a view) and leaves the tables and their
#      rows alone.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
subtest 'diff-view' => sub {
  my $DB = "mysql_k79_$$";

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
  # %sources: Moniker => { table, columns => [...], pk, view => 'SELECT ...' }
  my $schema_version = sub {
    my (%sources) = @_;
    my $ns = 'K79Live::V' . ++$version;
    eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
    for my $moniker (sort keys %sources) {
      my $def   = $sources{$moniker};
      my $class = "${ns}::Result::$moniker";
      eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
      $class->table_class('DBIO::ResultSource::View') if $def->{view};
      $class->table($def->{table});
      $class->result_source_instance->view_definition($def->{view}) if $def->{view};
      $class->add_columns(@{ $def->{columns} });
      $class->set_primary_key($def->{pk}) if $def->{pk};
      $ns->register_class($moniker => $class);
    }
    return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
  };

  my @ITEM = (
    id   => { data_type => 'int', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 20 },
    n    => { data_type => 'int' },
  );
  my @ITEM_V2 = (@ITEM, extra => { data_type => 'int', is_nullable => 1 });
  my @EXTRA = (id => { data_type => 'int' });

  my $item = sub { my ($cols) = @_; return (Item => { table => 'item', columns => $cols // \@ITEM, pk => 'id' }) };
  my $big = sub { my ($def) = @_; return (VBig => { table => 'v_big', columns => [ id => { data_type => 'int' }, name => { data_type => 'varchar', size => 20 } ], view => $def }) };

  my $views_in_db = sub {
    return $raw->selectcol_arrayref(
      'SELECT table_name FROM information_schema.tables WHERE table_schema = ? AND table_type = ? ORDER BY table_name',
      undef, $DB, 'VIEW');
  };
  my $tables_in_db = sub {
    return $raw->selectcol_arrayref(
      'SELECT table_name FROM information_schema.tables WHERE table_schema = ? AND table_type = ? ORDER BY table_name',
      undef, $DB, 'BASE TABLE');
  };
  my $sql_of = sub { return [ map { $_->as_sql } @{ $_[0]->operations } ] };

  # 1. install
  my $s1 = $schema_version->($item->(), $big->('SELECT id, name FROM item WHERE n > 1'));
  ok eval { DBIO::MySQL::Deploy->new(schema => $s1)->install; 1 }, 'version 1 installs' or diag $@;
  is_deeply $views_in_db->(), ['v_big'], '... the view is a view' ;
  is_deeply $tables_in_db->(), ['item'], '... and the only table is the table';

  $raw->do("INSERT INTO `$DB`.`item` (`name`, `n`) VALUES ('a', 1), ('b', 2), ('c', 3)");

  my $again = eval { DBIO::MySQL::Deploy->new(schema => $s1)->diff };
  ok $again && !$again->has_changes, 'the diff right after install has nothing to say'
    or diag $again ? explain $sql_of->($again) : "the diff failed: $@";

  # 2. change one view, add one over a new table, add a column
  my $s2 = $schema_version->(
    $item->(\@ITEM_V2),
    $big->('SELECT id, name, n FROM item WHERE n > 1'),
    (Extra => { table => 'extra', columns => \@EXTRA, pk => 'id' }),
    (VExtra => { table => 'v_extra', columns => [ id => { data_type => 'int' } ], view => 'SELECT id FROM extra' }),
  );
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade };
  ok $diff && !$@, 'the upgrade runs' or diag "upgrade failed: $@";
  my $sql = $diff ? $sql_of->($diff) : [];
  note "  $_" for @$sql;

  is $sql->[0], 'DROP VIEW `v_big`;', 'the changed view is dropped first';
  my ($create_extra) = grep { $sql->[$_] =~ /\ACREATE TABLE `extra`/ } 0 .. $#$sql;
  my ($create_vextra) = grep { $sql->[$_] =~ /\ACREATE VIEW `v_extra`/ } 0 .. $#$sql;
  my ($create_vbig)   = grep { $sql->[$_] =~ /\ACREATE VIEW `v_big`/ } 0 .. $#$sql;
  my ($add_column)    = grep { $sql->[$_] =~ /\AALTER TABLE `item` ADD COLUMN `extra`/ } 0 .. $#$sql;
  ok defined $create_extra && defined $create_vextra && $create_extra < $create_vextra,
    'the new view is created after the new table' or diag explain $sql;
  ok defined $add_column && defined $create_vbig && $add_column < $create_vbig,
    'the changed view is created after the column change' or diag explain $sql;
  is scalar(grep { /CREATE TABLE `v_|DROP TABLE|ALTER TABLE `v_/ } @$sql), 0,
    'no TABLE statement is written for a view' or diag explain $sql;
  is_deeply $views_in_db->(), [ 'v_big', 'v_extra' ], 'both views exist as views';
  is_deeply $tables_in_db->(), [ 'extra', 'item' ], '... and the tables as tables';
  is_deeply $raw->selectall_arrayref("SELECT id, name, n FROM `$DB`.`v_big` ORDER BY id"),
    [ [ 2, 'b', 2 ], [ 3, 'c', 3 ] ], 'the changed view answers with its new definition';
  is $diff->classify->{class}, 'changing', 'the upgrade counts as changing, the replaced view is not a removal'
    or diag explain $diff->classify;

  my $after = eval { DBIO::MySQL::Deploy->new(schema => $s2)->diff };
  ok $after && !$after->has_changes, 'the next diff has nothing left'
    or diag $after ? explain $sql_of->($after) : "the diff failed: $@";
  my $second = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade };
  ok !$@ && (!$second || !$second->has_changes), 'a second upgrade has nothing to do' or diag $@;

  # 3. views gone
  my $s3 = $schema_version->($item->(\@ITEM_V2), (Extra => { table => 'extra', columns => \@EXTRA, pk => 'id' }));
  my $gone = eval { DBIO::MySQL::Deploy->new(schema => $s3)->upgrade(allow_destructive => 1) };
  ok $gone && !$@, 'the upgrade to a schema without views runs' or diag "upgrade failed: $@";
  my $gone_sql = $gone ? $sql_of->($gone) : [];
  note "  $_" for @$gone_sql;
  is_deeply $gone_sql, [ 'DROP VIEW `v_extra`;', 'DROP VIEW `v_big`;' ],   # views free of each other: the reverse of the creation order (karr k110)
    'the views are dropped with DROP VIEW and nothing else happens';
  is_deeply $views_in_db->(), [], '... no view is left';
  is_deeply $tables_in_db->(), [ 'extra', 'item' ], '... and both tables are';
  is $raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.`item`"), 3, '... with their rows';
  is $gone->classify->{class}, 'destructive', 'a removal is destructive';

  my $last = eval { DBIO::MySQL::Deploy->new(schema => $s3)->diff };
  ok $last && !$last->has_changes, 'the diff after it has nothing left'
    or diag $last ? explain $sql_of->($last) : "the diff failed: $@";

  $_->storage->disconnect for $s1, $s2, $s3;
  $drop_database->();
  $raw->disconnect;
  undef $raw;
};

# LIVE half of karr k110 (subtest ddl-view-order of t/135-ddl-view.t has the offline half and the reasoning): views
# that read other views are created in the order of what they read and dropped
# in the reverse, by the install and by the upgrade, on MySQL and MariaDB.
#
# WHY IT NEEDS A SERVER. The refusal is the server's: CREATE VIEW of a reader
# before the view it reads fails with 1146. And what a view reads has to be read
# from the definition the server hands back, in the server's own spelling, which
# differs between MySQL and MariaDB (MariaDB leaves the database off a column
# qualifier; MySQL has information_schema.view_table_usage, MariaDB has not).
#
# What the file claims, in a database of its own:
#   1. the server's own list of what a view reads (MySQL 8: view_table_usage)
#      equals what view_reads finds in the definitions the server stored; on a
#      server without that table the claim is skipped, and said so;
#   2. install creates three groups of views -- readers that sort before what
#      they read (w_a > w_b > w_c), readers that sort after (w_x < w_y < w_z), a
#      diamond (w_m reads w_n and w_o, both read w_p) -- and the diff after it is
#      empty;
#   3. an upgrade that changes w_b and w_c (reader and read), w_y and w_z, and
#      adds w_new1 reading w_new2: drops reader first, creates reader last, w_a
#      (unchanged, reads w_b) is replaced with them (karr k113), the views that
#      read nothing that changed (w_m, ...) are untouched, the views
#      answer with their new definition, the next diff is empty and a second
#      upgrade does nothing;
#   4. views that read each other in a cycle: the upgrade throws a
#      DBIO::Exception naming them, the views and rows in the database are as
#      they were, and no temporary database is left behind;
#   5. an upgrade to a schema without views drops every reader before what it
#      reads, and leaves the tables and their rows alone.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
subtest 'diff-view-order' => sub {
  my $DB = "mysql_k110_$$";

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
  # %views: view name => definition
  my $schema_version = sub {
    my (%views) = @_;
    my $ns = 'K110Live::V' . ++$version;
    eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
    my $item = "${ns}::Result::Item";
    eval "package $item; use DBIO 'Core', -mysql; 1" or die $@;
    $item->table('item');
    $item->add_columns(id => { data_type => 'int', is_auto_increment => 1 }, n => { data_type => 'int' });
    $item->set_primary_key('id');
    $ns->register_class(Item => $item);
    my $k = 0;
    for my $name (sort keys %views) {
      # the monikers run against the view names: source order is not view order
      my $moniker = sprintf 'V%02d_%s', 90 - $k++, $name;
      my $class = "${ns}::Result::$moniker";
      eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
      $class->table_class('DBIO::ResultSource::View');
      $class->table($name);
      $class->result_source_instance->view_definition($views{$name});
      $class->add_columns(id => { data_type => 'int' });
      $ns->register_class($moniker => $class);
    }
    return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
  };

  my %V1 = (
    # readers that sort before what they read
    w_a => 'SELECT id FROM w_b',
    w_b => 'SELECT id FROM w_c WHERE id > 0',
    w_c => 'SELECT id FROM item',
    # readers that sort after
    w_x => 'SELECT id FROM item',
    w_y => 'SELECT id FROM w_x',
    w_z => 'SELECT id FROM w_y',
    # a diamond
    w_m => 'SELECT w_n.id FROM w_n JOIN w_o ON w_n.id = w_o.id',
    w_n => 'SELECT id FROM w_p',
    w_o => 'SELECT id FROM w_p',
    w_p => 'SELECT id FROM item',
    # names in a string and a comment are no reads
    w_s => q{SELECT id, 'from w_a' AS note /* from w_z */ FROM item},
  );
  my %READS = (w_a => ['w_b'], w_b => ['w_c'], w_y => ['w_x'], w_z => ['w_y'],
    w_m => [qw(w_n w_o)], w_n => ['w_p'], w_o => ['w_p']);

  my $views_in_db = sub {
    return $raw->selectcol_arrayref(
      'SELECT table_name FROM information_schema.tables WHERE table_schema = ? AND table_type = ? ORDER BY table_name',
      undef, $DB, 'VIEW');
  };
  my $sql_of = sub { return [ map { $_->as_sql } @{ $_[0]->operations } ] };
  my $position_of = sub {
    my ($sql, $re) = @_;
    my ($i) = grep { $sql->[$_] =~ $re } 0 .. $#$sql;
    return $i;
  };
  my $order_ok = sub {    # every pair (reader, read): $first_is -> 'read' or 'reader' comes first
    my ($sql, $verb, $reader_first, $edges) = @_;
    my @bad;
    for my $reader (sort keys %$edges) {
      for my $read (@{ $edges->{$reader} }) {
        my ($pa, $pb) = map { $position_of->($sql, qr/\A$verb VIEW `$_`/) } $reader, $read;
        next unless defined $pa && defined $pb;
        push @bad, "$reader/$read" unless $reader_first ? $pa < $pb : $pb < $pa;
      }
    }
    return \@bad;
  };
  my $no_temp_db_left = sub {
    my $like = "\\_dbio\\_tmp\\_$$\\_%";
    return $raw->selectrow_array('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name LIKE ?', undef, $like);
  };

  # 2. install
  my $s1 = $schema_version->(%V1);
  ok eval { DBIO::MySQL::Deploy->new(schema => $s1)->install; 1 }, 'install creates views that read views, in any name order' or diag $@;
  is_deeply $views_in_db->(), [ sort keys %V1 ], '... all of them exist as views';
  $raw->do("INSERT INTO `$DB`.`item` (`n`) VALUES (1), (2), (3)");
  is $raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.`w_a`"), 3, '... and the outermost reader answers through the chain';

  my $again = eval { DBIO::MySQL::Deploy->new(schema => $s1)->diff };
  ok $again && !$again->has_changes, 'the diff right after install has nothing to say'
    or diag $again ? explain $sql_of->($again) : "the diff failed: $@";

  # 1. the server's own list against view_reads
  {
    my $have = eval {
      $raw->selectall_arrayref(
        'SELECT view_name, table_name FROM information_schema.view_table_usage WHERE view_schema = ?', undef, $DB);
    };
    if ($have) {
      my %server;
      $server{ $_->[0] }{ $_->[1] } = 1 for @$have;
      my %views = map { $_ => 1 } @{ $views_in_db->() };
      my %found;
      my $defs = $raw->selectall_arrayref('SELECT table_name, view_definition FROM information_schema.views WHERE table_schema = ?', undef, $DB);
      for my $row (@$defs) {
        $found{ $row->[0] } = [ sort grep { $views{$_} } DBIO::MySQL::DDL::view_reads($row->[1]) ];
      }
      my %want = map { $_ => [ sort grep { $views{$_} } keys %{ $server{$_} // {} } ] } keys %found;
      is_deeply \%found, \%want, 'view_reads finds the same views as information_schema.view_table_usage' or diag explain [ \%found, \%want ];
    }
    else {
      my $err = "$@"; $err =~ s/ at .*//s;
      note "this server has no information_schema.view_table_usage ($err): the claim is not made here";
      my $defs = $raw->selectall_arrayref('SELECT table_name, view_definition FROM information_schema.views WHERE table_schema = ?', undef, $DB);
      my %views = map { $_ => 1 } @{ $views_in_db->() };
      my %found = map { $_->[0] => [ sort grep { $views{$_} } DBIO::MySQL::DDL::view_reads($_->[1]) ] } @$defs;
      is_deeply \%found, { map { $_ => [ sort @{ $READS{$_} // [] } ] } keys %V1 },
        'view_reads finds, in the definitions this server stored, what the schema declared' or diag explain \%found;
    }
  }

  # 3. an upgrade
  my %V2 = (%V1,
    w_b => 'SELECT id FROM w_c WHERE id > 1',
    w_c => 'SELECT id FROM item WHERE id > 0',
    w_y => 'SELECT id FROM w_x WHERE id > 0',
    w_z => 'SELECT id FROM w_y WHERE id > 0',
    w_new1 => 'SELECT id FROM w_new2',
    w_new2 => 'SELECT id FROM item',
  );
  my $s2 = $schema_version->(%V2);
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade };
  ok $diff && !$@, 'the upgrade runs, the server takes every statement' or diag "upgrade failed: $@";
  my $sql = $diff ? $sql_of->($diff) : [];
  note "  $_" for @$sql;
  my @views_sql = grep { /VIEW/ } @$sql;
  is scalar(@views_sql), 2 * 5 + 2, 'five views are replaced (a drop and a create each; w_a with them, it reads w_b), two are new';
  is_deeply $order_ok->($sql, 'DROP', 1, { w_b => ['w_c'], w_z => ['w_y'] }), [], 'a changed reader is dropped before the changed view it reads';
  is_deeply $order_ok->($sql, 'CREATE', 0, { w_b => ['w_c'], w_z => ['w_y'], w_new1 => ['w_new2'] }), [],
    '... and created after it, new views included';
  is scalar(grep { /\A(?:DROP|CREATE) VIEW `(?:w_m|w_n|w_o|w_p|w_x|w_s)`/ } @views_sql), 0, 'the views that did not change and read nothing that did are left alone';
  is scalar(grep { /\A(?:DROP|CREATE) TABLE/ } @$sql), 0, 'no TABLE statement is written';
  is_deeply $views_in_db->(), [ sort keys %V2 ], 'every view exists as a view';
  is $raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.`w_a`"), 2, 'the outermost reader answers with the new definitions through the chain';
  is $raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.`w_new1`"), 3, 'the new reader answers';

  my $after = eval { DBIO::MySQL::Deploy->new(schema => $s2)->diff };
  ok $after && !$after->has_changes, 'the next diff has nothing left' or diag $after ? explain $sql_of->($after) : "the diff failed: $@";
  my $second = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade };
  ok !$@ && (!$second || !$second->has_changes), 'a second upgrade does nothing' or diag $@;

  # 4. a cycle
  {
    my $s_cycle = $schema_version->(%V2, w_q => 'SELECT id FROM w_r', w_r => 'SELECT id FROM w_s2', w_s2 => 'SELECT id FROM w_q');
    my $r = eval { DBIO::MySQL::Deploy->new(schema => $s_cycle)->upgrade };
    my $err = $@;
    ok !$r, 'views in a cycle: the upgrade does not run';
    ok ref $err && $err->isa('DBIO::Exception'), '... it throws a DBIO::Exception';
    like "$err", qr/`w_q`.*`w_r`.*`w_s2`/s, '... naming the views of the cycle';
    is_deeply $views_in_db->(), [ sort keys %V2 ], '... the views in the database are as they were';
    is $raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.`item`"), 3, '... and the rows';
    is $no_temp_db_left->(), 0, '... and no temporary database is left behind';
  }

  # 5. views gone
  my $s3 = $schema_version->();
  my $gone = eval { DBIO::MySQL::Deploy->new(schema => $s3)->upgrade(allow_destructive => 1) };
  ok $gone && !$@, 'the upgrade to a schema without views runs' or diag "upgrade failed: $@";
  my $gone_sql = $gone ? $sql_of->($gone) : [];
  note "  $_" for @$gone_sql;
  is scalar(@$gone_sql), scalar(keys %V2), 'every view is dropped, nothing else happens';
  my %reads2 = (%READS, w_new1 => ['w_new2']);
  is_deeply $order_ok->($gone_sql, 'DROP', 1, \%reads2), [], 'every reader is dropped before the views it reads';
  is_deeply $views_in_db->(), [], 'no view is left';
  is $raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.`item`"), 3, 'the table keeps its rows';

  $_->storage->disconnect for $s1, $s2, $s3;
  $drop_database->();
  $raw->disconnect;
  undef $raw;
};

# LIVE half of karr k113 (subtest diff-view-readers of t/121-diff-view.t has the offline half and the reasoning): a view
# that reads a view being replaced is dropped before it and created again
# after it, on MySQL and MariaDB.
#
# WHY IT NEEDS A SERVER. The servers let a view be dropped that others read,
# and the reader is silently broken when the new definition lost a column it
# reads (1356 at the first query). Only a server shows that the re-created
# reader is checked against the new definition, and fails the apply when it
# does not fit.
#
# What the file claims, in a database of its own:
#   1. an upgrade that changes w_c, read by w_b (unchanged), read by w_a
#      (unchanged): all three are dropped and created again, the view beside
#      (w_z) is not, every view answers, the next diff is empty and a second
#      upgrade does nothing;
#   2. an upgrade whose new w_c lost a column that w_b reads fails loudly: the
#      DBIO::MySQL::Deploy upgrade throws, naming the server's refusal, instead
#      of leaving a broken w_b.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
subtest 'diff-view-readers' => sub {
  my $DB = "mysql_k113_$$";

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
    my (%views) = @_;
    my $ns = 'K113Live::V' . ++$version;
    eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
    my $item = "${ns}::Result::Item";
    eval "package $item; use DBIO 'Core', -mysql; 1" or die $@;
    $item->table('item');
    $item->add_columns(id => { data_type => 'int', is_auto_increment => 1 }, n => { data_type => 'int' });
    $item->set_primary_key('id');
    $ns->register_class(Item => $item);
    my $k = 0;
    for my $name (sort keys %views) {
      my $moniker = sprintf 'V%02d_%s', 90 - $k++, $name;
      my $class = "${ns}::Result::$moniker";
      eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
      $class->table_class('DBIO::ResultSource::View');
      $class->table($name);
      $class->result_source_instance->view_definition($views{$name});
      $class->add_columns(id => { data_type => 'int' });
      $ns->register_class($moniker => $class);
    }
    return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
  };
  my $sql_of = sub { return [ map { $_->as_sql } @{ $_[0]->operations } ] };
  my $views_in_db = sub {
    return $raw->selectcol_arrayref(
      'SELECT table_name FROM information_schema.tables WHERE table_schema = ? AND table_type = ? ORDER BY table_name',
      undef, $DB, 'VIEW');
  };
  my $no_temp_db_left = sub {
    my $like = "\\_dbio\\_tmp\\_$$\\_%";
    return $raw->selectrow_array('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name LIKE ?', undef, $like);
  };

  my %V1 = (
    w_a => 'SELECT id FROM w_b',
    w_b => 'SELECT id, n FROM w_c',
    w_c => 'SELECT id, n FROM item',
    w_z => 'SELECT id FROM item',
  );
  my $s1 = $schema_version->(%V1);
  ok eval { DBIO::MySQL::Deploy->new(schema => $s1)->install; 1 }, 'install' or diag $@;
  $raw->do("INSERT INTO `$DB`.`item` (`n`) VALUES (1), (2), (3)");

  # 1. the reader is replaced
  my %V2 = (%V1, w_c => 'SELECT id, n FROM item WHERE id > 1');
  my $s2 = $schema_version->(%V2);
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade };
  ok $diff && !$@, 'the upgrade runs' or diag "upgrade failed: $@";
  my $sql = $diff ? $sql_of->($diff) : [];
  note "  $_" for @$sql;
  is_deeply [ map { /\A(DROP|CREATE) VIEW `(\w+)`/ ? "$1 $2" : () } @$sql ],
    ['DROP w_a', 'DROP w_b', 'DROP w_c', 'CREATE w_c', 'CREATE w_b', 'CREATE w_a'],
    'w_c changed: w_b and w_a, unchanged, are dropped before it and created after it; w_z stays';
  is_deeply $views_in_db->(), [ sort keys %V1 ], 'every view exists as a view';
  is $raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.`w_a`"), 2, 'the outermost reader answers through the chain with the new definition';
  my $after = eval { DBIO::MySQL::Deploy->new(schema => $s2)->diff };
  ok $after && !$after->has_changes, 'the next diff has nothing left' or diag $after ? explain $sql_of->($after) : "the diff failed: $@";
  my $second = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade };
  ok !$@ && (!$second || !$second->has_changes), 'a second upgrade does nothing' or diag $@;

  # 2. a reader that no longer fits fails loudly
  {
    my $s3 = $schema_version->(%V2, w_c => 'SELECT id FROM item');    # w_b reads n
    my $r = eval { DBIO::MySQL::Deploy->new(schema => $s3)->upgrade };
    my $err = $@;
    ok !$r, 'the new w_c lost a column w_b reads: the upgrade fails';
    like "$err", qr/w_b|n\b|Unknown column|1054|1356/i, '... and the message is the server\'s refusal, not silence' or diag "$err";
    $s3->storage->disconnect;
  }

  $_->storage->disconnect for $s1, $s2;
  $drop_database->();
  $raw->disconnect;
  undef $raw;
};

done_testing;
