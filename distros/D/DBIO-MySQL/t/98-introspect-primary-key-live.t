use strict;
use warnings;
use Test::More;

# LIVE half of karr k83 (t/97 has the offline half and the measurement): a
# table without a primary key but with a UNIQUE key over NOT NULL columns is
# not given one by upgrade().
#
# WHY IT MATTERS. Both servers report COLUMN_KEY = 'PRI' for such a column.
# Introspect::Columns took that as is_pk, so Diff::Table wrote a PRIMARY KEY
# into the CREATE TABLE of the table, one the schema never declared. Claims,
# on MySQL and on MariaDB:
#   1. the introspection reads is_pk only for the columns of a real primary
#      key (single and composite), not for a UNIQUE one;
#   2. upgrade() creating a table without primary key (UNIQUE over a NOT NULL
#      column) writes no PRIMARY KEY, and the server has none (no index
#      PRIMARY) afterwards;
#   3. a table with a composite primary key keeps exactly that one;
#   4. the next diff has nothing left.
# Works in a database of its own (see t/88).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use DBIO::MySQL::Introspect;

my $DB = "dbio_k83_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END { if ($raw) { local ($@, $?); eval { drop_database() } } }

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}
note sprintf 'server %s, database %s', scalar $raw->selectrow_array('SELECT VERSION()'), $DB;

my $n = 0;
sub make_schema {
  my (%sources) = @_;
  my $ns = 'K83Live::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $moniker (sort keys %sources) {
    my ($cols, $pk, $unique) = @{ $sources{$moniker} };
    my $class = "${ns}::Result::$moniker";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table(lc $moniker);
    $class->add_columns(@$cols);
    $class->set_primary_key(@$pk) if $pk;
    $class->add_unique_constraint(@$unique) if $unique;
    $ns->register_class($moniker => $class);
  }
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

my %sources = (
  Nopk  => [ [ code => { data_type => 'int' }, label => { data_type => 'int', is_nullable => 1 } ],
             undef, [ nopk_code => ['code'] ] ],
  Comp  => [ [ a => { data_type => 'int' }, b => { data_type => 'int' }, c => { data_type => 'int' } ],
             [qw(b a)], [ comp_c => ['c'] ] ],
);
my $schema = make_schema(%sources);

my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade };
ok !$@, 'upgrade creates the tables' or diag $@;
my $sql = join "\n", map { $_->as_sql } @{ $diff ? $diff->operations : [] };
like $sql, qr/CREATE TABLE `nopk`/, '... the table without a primary key is created';
my ($nopk_sql) = $sql =~ /(CREATE TABLE `nopk`.*?;)/s;
unlike $nopk_sql // '', qr/PRIMARY KEY/, '... without a PRIMARY KEY';

sub primary_cols {
  my ($t) = @_;
  return [ map { $_->[0] } @{ $raw->selectall_arrayref(
    "SELECT column_name FROM information_schema.statistics WHERE table_schema = ? AND table_name = ? "
  . "AND index_name = 'PRIMARY' ORDER BY seq_in_index", undef, $DB, $t) } ];
}
is_deeply primary_cols('nopk'), [], 'the server has no PRIMARY index on it';
is_deeply primary_cols('comp'), [qw(b a)], 'and the composite one keeps its own, in its order (karr k107)';

# A second upgrade has to find nothing to do, not a primary key to drop or add.
$raw->do("USE `$DB`");
my $model = DBIO::MySQL::Introspect->new(dbh => $raw)->model;
my %pk = map { my $t = $_; ($t => [ sort map { $_->{column_name} } grep { $_->{is_pk} } @{ $model->{columns}{$t} } ]) } qw(nopk comp);
my ($key) = $raw->selectrow_array("SELECT column_key FROM information_schema.columns "
  . "WHERE table_schema = ? AND table_name = 'nopk' AND column_name = 'code'", undef, $DB);
note "COLUMN_KEY of nopk.code on this server: " . ($key // '(undef)');
is_deeply $pk{nopk}, [], 'the introspection reads is_pk for no column of the table without a primary key';
is_deeply $pk{comp}, [qw(a b)], '... and for exactly the columns of the composite one';

my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
ok $again && !$again->has_changes, 'the next diff has nothing left'
  or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";

$schema->storage->disconnect;
drop_database();
$raw->disconnect;
undef $raw;
done_testing;
