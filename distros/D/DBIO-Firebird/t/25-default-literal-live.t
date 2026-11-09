use strict;
use warnings;
use Test::More;

# Live: a string default holding an apostrophe (karr k47). Before the fix
# install_ddl wrote DEFAULT 'it's' and the server refused the statement; now
# the table installs, an insert without the column reads the value back, and
# the introspected default is the server's spelling of the same literal,
# which the Diff ops then pass through (the diff is empty).
#
# Skipped unless a DSN is provided (as t/15, t/17):
#
#   DBIO_TEST_FIREBIRD_DSN
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS
#
# WARNING: creates and drops the table "artist".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live default-literal test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Deploy;
use DBIO::Firebird::Introspect;

{
  package DBIO::Firebird::Test::K47LiveSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Firebird');
  __PACKAGE__->load_classes({ 'DBIO::Test::Schema' => [qw/ Artist /] });
}

# Artist.name is the nullable VARCHAR(100); give it the default under test.
DBIO::Firebird::Test::K47LiveSchema->source('Artist')
  ->column_info('name')->{default_value} = q{it's};

my $schema = DBIO::Firebird::Test::K47LiveSchema->connect($dsn, $user, $pass, {
  quote_names     => 1,
  on_connect_call => 'use_softcommit',
});

eval { $schema->storage->dbh->do('SELECT 1 FROM rdb$database'); 1 }
  or plan skip_all => "Cannot reach Firebird server: $@";

$SIG{__WARN__} = sub {
  warn @_ unless $_[0] =~ /^non-transactional DDL on /;
};

sub cleanup {
  $schema->storage->disconnect;
  my $dbh = DBI->connect($dsn, $user, $pass,
    { RaiseError => 0, PrintError => 0, AutoCommit => 1, ib_dialect => 3 })
    or return;
  $dbh->do('DROP TABLE "artist"');
  $dbh->disconnect;
}

cleanup();

my $deploy = DBIO::Firebird::Deploy->new(schema => $schema);

ok(eval { $deploy->install; 1 }, 'install: the server accepts DEFAULT \'it\'\'s\'')
  or diag $@;

SKIP: {
  skip 'no table', 3 unless $schema->storage->dbh->selectrow_array(
    q{SELECT COUNT(*) FROM rdb$relations WHERE rdb$relation_name = 'artist'});

  $schema->resultset('Artist')->create({ artistid => 1 });
  my ($name) = $schema->storage->dbh->selectrow_array(
    'SELECT "name" FROM "artist" WHERE "artistid" = 1');
  is($name, q{it's}, 'an insert without a value reads back the default, apostrophe intact');

  my $model = DBIO::Firebird::Introspect->new(dbh => $schema->storage->dbh)->model;
  my ($col) = grep { $_->{column_name} eq 'name' } @{ $model->{columns}{artist} };
  is($col && $col->{default_value}, q{'it''s'},
    'introspected default is the doubled literal');

  my $diff = $deploy->diff;
  ok(!$diff->has_changes, 'the diff against the installed table is empty')
    or diag $diff->as_sql;
}

cleanup();
done_testing;
