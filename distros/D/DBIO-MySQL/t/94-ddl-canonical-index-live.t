use strict;
use warnings;
use Test::More;

# LIVE half of karr k97 (core k333, ADR 0061): an index declared with Cake
# idx / indices is created by install, and an upgrade of a database that has
# the table without it creates it. The diff target model is deployed through
# install_ddl into a temp database, so what is claimed here is that the
# canonical declaration reaches the server by both routes, on MySQL and
# MariaDB, and that the diff of the same schema then has nothing to say.
#
# Works in a database of its own, created and dropped here.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use DiffTempDbProbe qw(temp_db_skip_reason);

my $DB  = "dbio_k97_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END { if ($raw) { local ($@, $?); eval { drop_database() } } }

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}
if (my $why = temp_db_skip_reason($raw)) { plan skip_all => $why }
note sprintf 'server %s, database %s', scalar $raw->selectrow_array('SELECT VERSION()'), $DB;

my $n = 0;
sub schema_for {
  my ($with_idx) = @_;
  my $ns = 'K97Live::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  my $class = "${ns}::Result::Doc";
  eval "package $class; use DBIO::Cake; __PACKAGE__->load_components('MySQL::Result'); 1" or die $@;
  $class->table('docs');
  $class->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 64 },
    slug => { data_type => 'varchar', size => 64 },
  );
  $class->set_primary_key('id');
  if ($with_idx) {
    # what Cake idx / indices write
    my $source = $class->result_source_instance;
    $source->add_index_declaration({ name => 'idx_docs_name', columns => ['name'] });
    $source->add_index_declaration({ name => 'idx_docs_slug', columns => ['slug'], type => 'unique' });
  }
  $ns->register_class(Doc => $class);
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

sub server_keys {
  return { map { $_->[0] => $_->[1] ? 'plain' : 'unique' } @{ $raw->selectall_arrayref(
    'SELECT DISTINCT INDEX_NAME, NON_UNIQUE FROM information_schema.STATISTICS '
  . "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'docs' AND INDEX_NAME <> 'PRIMARY'", undef, $DB) } };
}

my $before = schema_for(0);
ok eval { DBIO::MySQL::Deploy->new(schema => $before)->install; 1 }, 'the schema without indexes installs'
  or diag $@;
is_deeply server_keys(), {}, 'to begin with the table has no index';
$before->storage->disconnect;

my $after = schema_for(1);
my $diff = eval { DBIO::MySQL::Deploy->new(schema => $after)->upgrade };
ok !$@, 'the upgrade to the schema with idx runs' or diag $@;
is_deeply server_keys(), { idx_docs_name => 'plain', idx_docs_slug => 'unique' },
  'the upgrade created the declared indexes';

my $again = eval { DBIO::MySQL::Deploy->new(schema => $after)->diff };
ok $again && !$again->has_changes, 'and the diff has nothing left'
  or diag $again ? join("\n", map { $_->as_sql } @{ $again->operations }) : "the diff failed: $@";
$after->storage->disconnect;

done_testing;
