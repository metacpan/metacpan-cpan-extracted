use strict;
use warnings;
use Test::More;

# LIVE half of karr k88: deploy_async(add_drop_table => 1) on the future_io
# transport runs over tables named with reserved words and a hyphen, on a server
# that already has such tables.
#
# WHY IT MATTERS. t/128 pins the statements of the DROP pre-pass. Whether the
# server takes `order` and `my-tab` in backticks in DROP TABLE IF EXISTS, and
# the install DDL after it, only a server can say; before k88 the pre-pass was
# refused with 1064 on the first of them. The database is made to hold tables
# of those names first, with a column the schema does not have and a row, so
# the DROP really drops something: that the deploy runs through and the tables
# are new -- the old column gone, the old row gone -- is the claim.
#
# karr k114 adds the views: the database holds a view over a table and a view
# over that view, and the deploy has to take them away before it installs the
# schema's own views of the same names -- CREATE VIEW has no OR REPLACE, so a
# view left behind fails the deploy, and a second run is the claim.
#
# Works in a database of its own (mysql_k88_<pid>), created and dropped here.
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS;
# runs through whichever DBD the DSN names.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io roundtrip';
}

eval { require DBIO::MySQL::Storage::Async; 1 }
  or plan skip_all => 'DBIO::Async not installed (recommends only)';

use DBI;

my ($dbd, $rest) = $dsn =~ /\Adbi:(\w+):(.*)\z/;
plan skip_all => 'DBIO_TEST_MYSQL_DSN names neither dbi:mysql: nor dbi:MariaDB:'
  unless defined $dbd && $dbd =~ /\A(?:mysql|MariaDB)\z/;

my $DB = "mysql_k88_$$";
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
  plan skip_all => "this account may not create a database of its own: $why";
}
note sprintf 'server %s, DBD::%s, database %s',
  scalar $raw->selectrow_array('SELECT VERSION()'), $dbd, $DB;

# the same server, our database
(my $rest2 = $rest) =~ s/(?:^|;)\s*(?:database|dbname)=[^;]*//g;
$rest2 =~ s/\A;//;
my $db_dsn = "dbi:$dbd:database=$DB" . (length $rest2 ? ";$rest2" : '');

{
  package DropLive::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
my %TABLES = (Order => 'order', Group => 'group', Hyphen => 'my-tab', Plain => 'mysql_plain');
for my $moniker (sort keys %TABLES) {
  my $class = "DropLive::Schema::Result::$moniker";
  eval sprintf q{
    package %s;
    use DBIO;
    __PACKAGE__->table(%s);
    __PACKAGE__->add_columns(
      id    => { data_type => 'integer', is_auto_increment => 1 },
      fresh => { data_type => 'varchar', size => 20 },
    );
    __PACKAGE__->set_primary_key('id');
    1;
  }, $class, "'$TABLES{$moniker}'" or die $@;
  DropLive::Schema->register_class($moniker => $class);
}

{
  package DropLive::Schema::Result::PlainView;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('mysql_plain_view');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->result_source_instance->view_definition('SELECT id FROM `mysql_plain`');
}
{
  package DropLive::Schema::Result::TopView;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('mysql_top_view');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->result_source_instance->view_definition('SELECT id FROM `mysql_plain_view`');
  __PACKAGE__->result_source_instance->deploy_depends_on({ 'DropLive::Schema::Result::PlainView' => 1 });
}
DropLive::Schema->register_class($_ => "DropLive::Schema::Result::$_") for qw(PlainView TopView);

# what is there before: the same names, another shape, a row each
$raw->do("USE `$DB`");
for my $t (sort values %TABLES) {
  $raw->do("CREATE TABLE `$t` (id INT PRIMARY KEY, old_col INT)");
  $raw->do("INSERT INTO `$t` VALUES (1, 1)");
}
$raw->do('CREATE VIEW `mysql_plain_view` AS SELECT old_col AS id FROM `mysql_plain`');
$raw->do('CREATE VIEW `mysql_top_view` AS SELECT id FROM `mysql_plain_view`');

my $schema = DropLive::Schema->connect({
  dsn => $db_dsn, user => $user, password => $pass,
  async => 'future_io', pool_size => 1,
});

my @warn;
{
  local $SIG{__WARN__} = sub { push @warn, @_ };
  my $f = $schema->storage->async->deploy_async($schema, { add_drop_table => 1 });
  ok eval { $f->get; 1 }, 'deploy_async(add_drop_table => 1) over reserved-word tables runs through'
    or diag $@;
}
unlike join('', @warn), qr/\b1064\b/, 'no syntax error on the way';

for my $t (sort values %TABLES) {
  my $cols = $raw->selectcol_arrayref(
    'SELECT column_name FROM information_schema.columns WHERE table_schema = ? AND table_name = ? ORDER BY ordinal_position',
    undef, $DB, $t);
  is_deeply [ map { lc } @$cols ], [qw(id fresh)], "`$t` is the schema's table: old column gone, new one there";
  my ($n) = $raw->selectrow_array("SELECT COUNT(*) FROM `$t`");
  is $n, 0, "`$t`: the old row went with the old table";
}

# the views are the schema's: they read the new table, which holds nothing
for my $v (qw(mysql_plain_view mysql_top_view)) {
  my ($n) = $raw->selectrow_array("SELECT COUNT(*) FROM `$v`");
  is $n, 0, "`$v` is the schema's view: it reads the new, empty table";
}

# and once more: the deploy is idempotent, with the views in place and a row behind them
{
  $raw->do("INSERT INTO `mysql_plain` (fresh) VALUES ('x')");
  local $SIG{__WARN__} = sub { };
  ok eval { $schema->storage->async->deploy_async($schema, { add_drop_table => 1 })->get; 1 },
    'a second run on the populated database, views included, runs through as well' or diag $@;
  my ($n) = $raw->selectrow_array('SELECT COUNT(*) FROM `mysql_top_view`');
  is $n, 0, 'the second run left the new tables empty and the views in place';
}

$schema->storage->disconnect;
done_testing;
