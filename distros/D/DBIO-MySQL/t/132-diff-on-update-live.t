use strict;
use warnings;
use Test::More;

# LIVE half of karr k108 (t/124 has the offline half and the reasoning): ON UPDATE
# CURRENT_TIMESTAMP survives every statement a diff writes, install_ddl puts it
# there, and a schema that drops it gets it removed.
#
# WHY IT MATTERS. The attribute sits in EXTRA, not in the default. A MODIFY
# COLUMN that names type, NOT NULL and DEFAULT only made the server drop it: the
# column stopped following the row's updates without anybody having asked for
# that. Run it on MySQL and on MariaDB; they report the attribute differently
# (EXTRA 'DEFAULT_GENERATED on update CURRENT_TIMESTAMP' against 'on update
# current_timestamp()').
#
# The declaration is the scalar reference a schema already writes:
#   default_value => \'CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'
#
# What this file claims:
#   1. install_ddl writes it: the introspection reads on_update for the columns
#      declared with it (also with a precision, CURRENT_TIMESTAMP(6)), the diff
#      right after install has nothing to say, and an UPDATE moves the column;
#   2. an upgrade that changes the type of such a column, one that changes its
#      default, one that adds a column with it and one that creates a table with
#      it all keep or write it -- read back from the server, and for the default
#      change by the row following an UPDATE;
#   3. an upgrade to a schema that no longer declares it removes it: the column
#      stays a column with its default, and an UPDATE leaves it alone;
#   4. after each upgrade the next diff has nothing left, and a second upgrade
#      does nothing.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/88).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use DBIO::MySQL::Introspect;

my $DB = "mysql_k108_$$";

my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END {
  if ($raw) {
    local ($@, $?);
    eval { drop_database() };
  }
}

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
}
note sprintf 'server %s', scalar $raw->selectrow_array('SELECT VERSION()');

my $version = 0;
# %tables: table => [ column definitions ]
sub schema_version {
  my (%tables) = @_;
  my $ns = 'K108Live::V' . ++$version;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $table (sort keys %tables) {
    my $class = "${ns}::Result::" . ucfirst $table;
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table($table);
    $class->add_columns(@{ $tables{$table} });
    $class->set_primary_key('id');
    $ns->register_class(ucfirst $table => $class);
  }
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

my $CT   = \'CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP';
my $CT6  = \'CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)';
my $LIT6 = \q{'2000-01-01 00:00:00.000000' ON UPDATE CURRENT_TIMESTAMP(6)};

sub item_columns {
  my (%c) = @_;
  return [
    id   => { data_type => 'int', is_auto_increment => 1 },
    n    => { data_type => 'int', is_nullable => 1 },
    ts   => { data_type => $c{ts}   // 'datetime',    default_value => $CT },
    ts6  => { data_type => 'datetime(6)', default_value => $c{ts6} // $CT6 },
    fine => { data_type => 'datetime(6)', default_value => $c{fine} // $CT6 },
    @{ $c{more} // [] },
  ];
}

sub on_update_of {
  my ($table) = @_;
  $raw->do("USE `$DB`");
  my $columns = DBIO::MySQL::Introspect->new(dbh => $raw)->model->{columns}{$table};
  return { map { $_->{column_name} => $_->{on_update} } @$columns };
}
sub sql_of { return [ map { $_->as_sql } @{ $_[0]->operations } ] }
sub nothing_left {
  my ($schema, $what) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $diff && !$diff->has_changes, $what
    or diag $diff ? explain sql_of($diff) : "the diff failed: $@";
}
sub upgrade {
  my ($schema) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade(allow_destructive => 1) };   # datetime to timestamp narrows the range: lossy by design; the claim is about ON UPDATE
  ok $diff && !$@, 'upgrade runs' or diag "upgrade failed: $@";
  my @sql = $diff ? @{ sql_of($diff) } : ();
  note "  $_" for @sql;
  return @sql;
}
# Updating n moves the time of a column that has ON UPDATE (microseconds apart)
# and leaves one that has not.
sub follows_update {
  my ($column) = @_;
  $raw->do("UPDATE `$DB`.`item` SET `$column` = '2001-02-03 04:05:06.000000'") if $column eq 'fine' || $column eq 'ts6';
  $raw->do("UPDATE `$DB`.`item` SET `n` = IFNULL(`n`, 0) + 1");
  my ($now) = $raw->selectrow_array("SELECT `$column` > '2001-02-04' FROM `$DB`.`item`");
  return $now ? 1 : 0;
}

# 1. install
my $s1 = schema_version(item => item_columns());
ok eval { DBIO::MySQL::Deploy->new(schema => $s1)->install; 1 }, 'version 1 installs' or diag $@;
$raw->do("INSERT INTO `$DB`.`item` (`n`) VALUES (1)");
is_deeply on_update_of('item'),
  { id => undef, n => undef, ts => 'CURRENT_TIMESTAMP', ts6 => 'CURRENT_TIMESTAMP(6)', fine => 'CURRENT_TIMESTAMP(6)' },
  'install_ddl writes ON UPDATE: the introspection reads it, with and without precision';
is follows_update('fine'), 1, '... and an UPDATE moves the column';
nothing_left($s1, 'the diff right after install has nothing to say');

# 2. type change, default change, new column, new table -- all under ON UPDATE
my $s2 = schema_version(
  item  => item_columns(ts => 'timestamp(0)', ts6 => $LIT6, more => [ added => { data_type => 'datetime', default_value => $CT } ]),
  other => [ id => { data_type => 'int', is_auto_increment => 1 }, u => { data_type => 'datetime', default_value => $CT } ],
);
my @sql = upgrade($s2);
ok scalar(grep { /MODIFY COLUMN `ts` timestamp .*ON UPDATE CURRENT_TIMESTAMP;\z/ } @sql), '... a type change is a MODIFY that carries ON UPDATE' or diag explain \@sql;
ok scalar(grep { /MODIFY COLUMN `ts6` .*ON UPDATE CURRENT_TIMESTAMP\(6\);\z/ } @sql), '... so is a default change' or diag explain \@sql;
ok scalar(grep { /ADD COLUMN `added` .*ON UPDATE CURRENT_TIMESTAMP;\z/ } @sql), '... ADD COLUMN writes it' or diag explain \@sql;
ok scalar(grep { /CREATE TABLE `other` .*`u` .*ON UPDATE CURRENT_TIMESTAMP/s } @sql), '... and so does CREATE TABLE' or diag explain \@sql;
is_deeply on_update_of('item'),
  { id => undef, n => undef, ts => 'CURRENT_TIMESTAMP', ts6 => 'CURRENT_TIMESTAMP(6)', fine => 'CURRENT_TIMESTAMP(6)', added => 'CURRENT_TIMESTAMP' },
  'the server has ON UPDATE on every column that was declared with it';
is_deeply on_update_of('other'), { id => undef, u => 'CURRENT_TIMESTAMP' }, '... also on the new table';
is follows_update('ts6'), 1, 'the column whose default changed still follows an UPDATE';
nothing_left($s2, 'the next diff has nothing left');
{
  my $second = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade };
  ok !$@ && (!$second || !$second->has_changes), 'a second upgrade does nothing' or diag $@;
}

# 3. the schema drops ON UPDATE from one column
my $s3 = schema_version(
  item  => item_columns(ts => 'timestamp(0)', ts6 => $LIT6, fine => \'CURRENT_TIMESTAMP(6)', more => [ added => { data_type => 'datetime', default_value => $CT } ]),
  other => [ id => { data_type => 'int', is_auto_increment => 1 }, u => { data_type => 'datetime', default_value => $CT } ],
);
@sql = upgrade($s3);
is scalar(@sql), 1, 'dropping ON UPDATE is one statement' or diag explain \@sql;
like $sql[0] // '', qr/MODIFY COLUMN `fine` datetime\(6\) NOT NULL DEFAULT CURRENT_TIMESTAMP\(6\);\z/i, '... a MODIFY without ON UPDATE';
is_deeply on_update_of('item'),
  { id => undef, n => undef, ts => 'CURRENT_TIMESTAMP', ts6 => 'CURRENT_TIMESTAMP(6)', fine => undef, added => 'CURRENT_TIMESTAMP' },
  '... and the server has it off that column only';
is follows_update('fine'), 0, 'an UPDATE leaves that column alone now';
nothing_left($s3, 'the next diff has nothing left');
{
  my $second = eval { DBIO::MySQL::Deploy->new(schema => $s3)->upgrade };
  ok !$@ && (!$second || !$second->has_changes), 'a second upgrade does nothing' or diag $@;
}

$s1->storage->disconnect;
$s2->storage->disconnect;
$s3->storage->disconnect;
drop_database();
$raw->disconnect;
undef $raw;

done_testing;
