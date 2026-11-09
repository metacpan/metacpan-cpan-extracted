use strict;
use warnings;
use Test::More;

# LIVE (karr k42): Deploy on a schema whose connection comes from an
# AccessBroker. The storage's connect_info is then [ $broker ] and holds
# nothing of the answer; DBIO::Firebird::Deploy reads the broker's current
# answer (the storage's normalised _dbi_connect_info) to find the live
# database's server and directory for the temp database, and to connect to it.
# Before k42 diff and upgrade died with "cannot find dbname=/database= in DSN
# ...Broker=HASH(...)".
#
# The whole path: install -> diff empty -> drift -> diff -> upgrade -> diff
# empty, and no temp database left behind.
#
# Skipped unless DBIO_TEST_FIREBIRD_DSN / _USER / _PASS are set.
# WARNING: creates and drops the table "artist".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live broker deploy test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::AccessBroker;
use DBIO::Firebird::Deploy;

{
  package T::K42Broker;
  use base 'DBIO::AccessBroker';
  sub connect_info_for {
    +{ dsn => $ENV{DBIO_TEST_FIREBIRD_DSN}, user => $ENV{DBIO_TEST_FIREBIRD_USER},
       password => $ENV{DBIO_TEST_FIREBIRD_PASS} };
  }
}

{
  package DBIO::Firebird::Test::K42Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Firebird');
  __PACKAGE__->load_classes({ 'DBIO::Test::Schema' => [qw/ Artist /] });
}

# unique constraints are the subject of t/29, not of this file
{
  my $s = DBIO::Firebird::Test::K42Schema->source('Artist');
  delete @{ $s->{_unique_constraints} }{ grep { $_ ne 'primary' } keys %{ $s->{_unique_constraints} } };
  $s->column_info('rank')->{is_nullable} = 0;
}

my $schema = DBIO::Firebird::Test::K42Schema->connect(bless {}, 'T::K42Broker');
isa_ok($schema->storage->access_broker, 'T::K42Broker', 'the schema runs on a broker');
is(ref $schema->storage->connect_info->[0], 'T::K42Broker', '... its connect_info is [ $broker ]');

eval { $schema->storage->dbh->do('SELECT 1 FROM rdb$database'); 1 }
  or plan skip_all => "Cannot reach Firebird server: $@";

my $other = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1, ib_dialect => 3,
});
$other->func(-lock_resolution => { wait => 10 }, 'ib_set_tx_param');

my @temp_ids;
{
  my $create = DBIO::Firebird::Deploy->can('_create_temp_db');
  no warnings 'redefine';
  *DBIO::Firebird::Deploy::_create_temp_db = sub {
    my $id = $create->(@_);
    push @temp_ids, $id;
    return $id;
  };
}
$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on / };

my $deploy = DBIO::Firebird::Deploy->new(schema => $schema);

cleanup();

ok(lives(sub { $deploy->install }), 'install on the broker schema');

my $diff = lives(sub { $deploy->diff });
ok($diff && !$diff->has_changes, 'diff is empty after install: the temp database was made from the broker answer')
  or diag($diff ? $diff->as_sql : 'no diff');

# drift behind the schema's back
$schema->storage->disconnect;
$other->do('ALTER TABLE "artist" DROP "name"');
$other->do(q{CREATE TABLE "k42_extra" ("id" INTEGER NOT NULL PRIMARY KEY)});

$diff = lives(sub { $deploy->diff });
ok($diff && $diff->has_changes, 'the drift is seen');
like($diff && $diff->as_sql, qr/ADD "name"/, '... as the missing column');

ok(lives(sub { $deploy->upgrade(allow_destructive => 1) }), 'upgrade on the broker schema');

$diff = lives(sub { $deploy->diff });
ok($diff && !$diff->has_changes, 'a second diff is empty')
  or diag($diff ? $diff->as_sql : 'no diff');

cleanup();

ok(scalar @temp_ids, 'the diffs went through temp databases (' . scalar(@temp_ids) . ')');
for my $id (@temp_ids) {
  my ($tdsn, $tuser, $tpass) = $deploy->_temp_connect_info($id);
  my $left = DBI->connect($tdsn, $tuser, $tpass, { RaiseError => 0, PrintError => 0, AutoCommit => 1 });
  ok(!$left, 'temp database is gone again');
  $left->func('ib_drop_database') if $left;
}

$other->disconnect;
$schema->storage->disconnect;
done_testing;

sub lives {
  my ($code) = @_;
  my $got = eval { $code->() // 1 };
  return $got || 1 unless $@;
  diag "died: $@";
  return;
}

sub cleanup {
  $schema->storage->disconnect;
  for my $drop ('DROP TABLE "k42_extra"', 'DROP TABLE "artist"', 'DROP TABLE artist') {
    eval { $other->do($drop) };
  }
  return;
}
