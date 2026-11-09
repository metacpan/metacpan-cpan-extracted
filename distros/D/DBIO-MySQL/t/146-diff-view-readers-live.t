use strict;
use warnings;
use Test::More;

# LIVE half of karr k113 (t/145 has the offline half and the reasoning): a view
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

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my $DB = "mysql_k113_$$";

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
sub schema_version {
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
}
sub sql_of { return [ map { $_->as_sql } @{ $_[0]->operations } ] }
sub views_in_db {
  return $raw->selectcol_arrayref(
    'SELECT table_name FROM information_schema.tables WHERE table_schema = ? AND table_type = ? ORDER BY table_name',
    undef, $DB, 'VIEW');
}
sub no_temp_db_left {
  my $like = "\\_dbio\\_tmp\\_$$\\_%";
  return $raw->selectrow_array('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name LIKE ?', undef, $like);
}

my %V1 = (
  w_a => 'SELECT id FROM w_b',
  w_b => 'SELECT id, n FROM w_c',
  w_c => 'SELECT id, n FROM item',
  w_z => 'SELECT id FROM item',
);
my $s1 = schema_version(%V1);
ok eval { DBIO::MySQL::Deploy->new(schema => $s1)->install; 1 }, 'install' or diag $@;
$raw->do("INSERT INTO `$DB`.`item` (`n`) VALUES (1), (2), (3)");

# 1. the reader is replaced
my %V2 = (%V1, w_c => 'SELECT id, n FROM item WHERE id > 1');
my $s2 = schema_version(%V2);
my $diff = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade };
ok $diff && !$@, 'the upgrade runs' or diag "upgrade failed: $@";
my $sql = $diff ? sql_of($diff) : [];
note "  $_" for @$sql;
is_deeply [ map { /\A(DROP|CREATE) VIEW `(\w+)`/ ? "$1 $2" : () } @$sql ],
  ['DROP w_a', 'DROP w_b', 'DROP w_c', 'CREATE w_c', 'CREATE w_b', 'CREATE w_a'],
  'w_c changed: w_b and w_a, unchanged, are dropped before it and created after it; w_z stays';
is_deeply views_in_db(), [ sort keys %V1 ], 'every view exists as a view';
is $raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.`w_a`"), 2, 'the outermost reader answers through the chain with the new definition';
my $after = eval { DBIO::MySQL::Deploy->new(schema => $s2)->diff };
ok $after && !$after->has_changes, 'the next diff has nothing left' or diag $after ? explain sql_of($after) : "the diff failed: $@";
my $second = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade };
ok !$@ && (!$second || !$second->has_changes), 'a second upgrade does nothing' or diag $@;

# 2. a reader that no longer fits fails loudly
{
  my $s3 = schema_version(%V2, w_c => 'SELECT id FROM item');    # w_b reads n
  my $r = eval { DBIO::MySQL::Deploy->new(schema => $s3)->upgrade };
  my $err = $@;
  ok !$r, 'the new w_c lost a column w_b reads: the upgrade fails';
  like "$err", qr/w_b|n\b|Unknown column|1054|1356/i, '... and the message is the server\'s refusal, not silence' or diag "$err";
  $s3->storage->disconnect;
}

$_->storage->disconnect for $s1, $s2;
drop_database();
$raw->disconnect;
undef $raw;

done_testing;
