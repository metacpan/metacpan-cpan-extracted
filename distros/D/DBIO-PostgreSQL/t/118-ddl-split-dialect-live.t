use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k125 (follow-up of core karr k332): the install of
# DDL that only PostgreSQL's reading of the text splits right, on a server.
#
# WHY: t/117-ddl-split-dialect.t pins what the splitter hands over. Whether
# the server then has what was written -- a routine with a BEGIN ATOMIC body,
# a statement carrying a nested block comment, a rule with two actions, a
# literal that ends on a backslash -- only a database says afterwards. A
# half-cut statement is a syntax error from the server, or worse, a different
# statement than the one written.
#
# Asked the way it matters: the function returns, the rule fires BOTH
# actions, and the two comments read back as they were written.
#
# The install goes into a database of this file's own (karr k81).

my $ddl_server;
{
  my $h = LiveServer->control_dbh(attrs => { RaiseError => 1, PrintError => 0, PrintWarn => 0 });
  $ddl_server = $h->selectrow_array('SHOW server_version_num');
  note 'server ' . $h->selectrow_array('SHOW server_version');
  $h->disconnect;
}
plan skip_all => 'BEGIN ATOMIC needs PostgreSQL 14'
  unless $ddl_server >= 140000;

{
  package T118::Result::Host;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('k125_host');
  __PACKAGE__->add_columns(id => { data_type => 'integer', is_nullable => 0 });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->pg_extra_ddl([
    'CREATE TABLE k125_log1 (id integer)',
    'CREATE TABLE k125_log2 (id integer)',
    "CREATE FUNCTION k125_add_one(a integer) RETURNS integer\n"
      . "  LANGUAGE sql\n"
      . "  BEGIN ATOMIC\n"
      . "    SELECT a + 1;\n"
      . "    SELECT a + 1;\n"
      . "  END",
    "COMMENT ON TABLE k125_log1 IS 'nested' /* outer /* inner; */ still outer; */",
    'CREATE RULE k125_ins AS ON INSERT TO k125_host DO ALSO ('
      . 'INSERT INTO k125_log1 VALUES (NEW.id); INSERT INTO k125_log2 VALUES (NEW.id))',
    q{COMMENT ON TABLE k125_host IS 'C:\\'},
    q{COMMENT ON TABLE k125_log2 IS 'a;b'},
  ]);
}
{
  package T118::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Host => 'T118::Result::Host');
}

my @db = PrivatePgDatabase->create('t118');
my $schema = T118::Schema->connect(@db, { PrintError => 0, PrintWarn => 0 });
ok(eval { $schema->pg_deploy->install; 1 }, 'install runs through')
  or diag "$@\n" . $schema->pg_install_ddl;
$schema->storage->disconnect;

my $dbh = LiveServer->control_dbh(login => \@db,
  attrs => { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1 });

is($dbh->selectrow_array('SELECT k125_add_one(41)'), 42,
  'the BEGIN ATOMIC routine is there whole, with both statements of its body');

$dbh->do('INSERT INTO k125_host VALUES (7)');
is_deeply($dbh->selectcol_arrayref('SELECT id FROM k125_log1'), [7],
  'the rule with two actions fired its first ...');
is_deeply($dbh->selectcol_arrayref('SELECT id FROM k125_log2'), [7],
  '... and its second');

my $comment = sub {
  $dbh->selectrow_array('SELECT obj_description(?::regclass, ?)', undef, $_[0], 'pg_class');
};
is($comment->('k125_log1'), 'nested', 'a comment nested in the statement did not cut it');
is($comment->('k125_host'), 'C:\\', 'a literal ending on a backslash ends there');
is($comment->('k125_log2'), 'a;b', 'and the literal behind it with a semicolon is its own');

$dbh->disconnect;

done_testing;
