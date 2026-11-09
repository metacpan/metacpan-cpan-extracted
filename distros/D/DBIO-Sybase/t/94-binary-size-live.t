use strict;
use warnings;

use Test::More;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use DBIO::Sybase::Deploy;
use DBIO::Sybase::Introspect;

# Live round-trip for the size of binary / varbinary columns (karr k93).
# syscolumns.length is the declared byte length; Introspect::Columns::_size
# returned nothing for these types, so a length change was invisible to the
# diff. Claims, asked of the server:
#
#   1. varbinary(16) and binary(4) read back with size 16 and 4.
#   2. A type written without a size (VARBINARY) is binary(1) in the catalog
#      and reads back as 1 -- and the diff against a schema of the same
#      declaration stays empty, the desired side being deployed the same way.
#   3. The diff of 16 -> 32 sees the length and alters the column; after the
#      apply the second diff is empty.
#
# Runs in a throwaway database it creates and drops itself; needs a login
# allowed to CREATE DATABASE.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && $user;

{
  package DBIO::Sybase::Test::K93::V1::Blob;
  use base 'DBIO::Core';
  __PACKAGE__->table('k93_blob');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    vb   => { data_type => 'varbinary', size => 16 },
    bn   => { data_type => 'binary', size => 4 },
    bare => { data_type => 'varbinary', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::Sybase::Test::K93::V1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Blob => 'DBIO::Sybase::Test::K93::V1::Blob');

  package DBIO::Sybase::Test::K93::V2::Blob;
  use base 'DBIO::Core';
  __PACKAGE__->table('k93_blob');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    vb   => { data_type => 'varbinary', size => 32 },
    bn   => { data_type => 'binary', size => 4 },
    bare => { data_type => 'varbinary', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::Sybase::Test::K93::V2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Blob => 'DBIO::Sybase::Test::K93::V2::Blob');
}

my $db = "dbio_k93_$$";
my $db_dsn = $dsn;
$db_dsn =~ s/\bdatabase=[^;]*/database=$db/i
  or $db_dsn .= ($dsn =~ /:$/ ? '' : ';') . "database=$db";

my $admin = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
$admin->do('USE master');
$admin->do("CREATE DATABASE $db");

my $ok = eval {
  my $v1 = DBIO::Sybase::Test::K93::V1->connect($db_dsn, $user, $pass);
  DBIO::Sybase::Deploy->new(schema => $v1)->install;

  my $cols = DBIO::Sybase::Introspect->new(dbh => $v1->storage->dbh)->model->{columns}{k93_blob};
  my %col  = map { $_->{column_name} => $_ } @$cols;
  is $col{vb}{data_type},   'varbinary', 'vb reads back as varbinary';
  is $col{vb}{size},        16, '... of length 16';
  is $col{bn}{data_type},   'binary', 'bn reads back as binary';
  is $col{bn}{size},        4,  '... of length 4';
  is $col{bare}{size},      1,  'a varbinary written without a size is the ASE default length 1';

  my $same = DBIO::Sybase::Deploy->new(schema => $v1)->diff;
  ok !$same->has_changes, 'the diff of the schema against its own deployment is empty'
    or diag $same->as_sql;
  $v1->storage->disconnect;

  my $v2 = DBIO::Sybase::Test::K93::V2->connect($db_dsn, $user, $pass);
  my $deploy = DBIO::Sybase::Deploy->new(schema => $v2);
  my $diff = $deploy->diff;
  my $sql  = $diff->as_sql;
  like $sql, qr/ALTER TABLE k93_blob\b.*\bvb\b.*(?i:varbinary)\(32\)/s,
    'the diff sees the length change 16 -> 32 and alters vb' or diag $sql;
  unlike $sql, qr/\b(?:bn|bare)\b/, '... and nothing else' or diag $sql;

  $deploy->apply($diff);
  my $cols2 = DBIO::Sybase::Introspect->new(dbh => $v2->storage->dbh)->model->{columns}{k93_blob};
  my ($vb) = grep { $_->{column_name} eq 'vb' } @$cols2;
  is $vb->{size}, 32, 'vb is varbinary(32) after the apply';
  my $again = $deploy->diff;
  ok !$again->has_changes, 'a second diff is empty' or diag $again->as_sql;
  $v2->storage->disconnect;
  1;
};
my $err = $@;

eval { $admin->do('USE master') };
is AseDatabase::drop($admin, $db), '', "the database of this test, $db, is dropped";

die $err unless $ok;

done_testing;
