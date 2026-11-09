use strict;
use warnings;
use Test::More;

# LIVE: the primary key of a table that exists (karr k58, k62).
#
# The model carries the key as is_pk / pk_position on the columns; its name is
# primary_key_name of the table. Claims only a server can answer:
#
#  * introspection reads the server's name of the key (INTEG_<n>);
#  * a database whose table has no primary key, or another one, than the schema
#    declares: the diff reports it and upgrade writes DROP CONSTRAINT <that
#    name> and ADD PRIMARY KEY (the server rejects a second key, so the old
#    one goes first), a new table beside it is created too;
#  * after that, the diff is empty.
#
# Skipped unless DBIO_TEST_FIREBIRD_DSN / _USER / _PASS are set (as t/29).
#
# WARNING: creates and drops the tables "k58_pk" and "k58_new".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live primary key test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Core;
use DBIO::Schema;
use DBIO::Firebird::Deploy;
use DBIO::Firebird::Introspect;

my $seq = 0;
sub build_schema {
  my (@sources) = @_;
  my $sc = 'K58Live::S' . ++$seq;
  no strict 'refs';
  @{"${sc}::ISA"} = ('DBIO::Schema');
  $sc->load_components('Firebird');
  for my $s (@sources) {
    my ($name, $table, $pk) = @$s;
    my $rc = "${sc}::Result::$name";
    @{"${rc}::ISA"} = ('DBIO::Core');
    $INC{ ($rc =~ s{::}{/}gr) . '.pm' } = 1;
    $rc->table($table);
    $rc->add_columns(map { $_ => { data_type => 'integer' } } qw/id c/);
    $rc->set_primary_key(@$pk);
    $sc->register_class($name => $rc);
  }
  return $sc;
}

my %connect = (quote_names => 1, on_connect_call => 'use_softcommit');
my $schema = build_schema([ Pk => 'k58_pk', ['id'] ])->connect($dsn, $user, $pass, {%connect});

eval { $schema->storage->dbh->do('SELECT 1 FROM rdb$database'); 1 }
  or plan skip_all => "Cannot reach Firebird server: $@";

my $other = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1, ib_dialect => 3,
}) or plan skip_all => 'Cannot connect: ' . DBI->errstr;
$other->func(-lock_resolution => { wait => 10 }, 'ib_set_tx_param');

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };

my @tables = qw(k58_new k58_pk);
my @schemas = ($schema);
sub cleanup { eval { $_->storage->disconnect } for grep { $_ } @schemas; eval { $other->do(qq{DROP TABLE "$_"}) } for @tables }
cleanup();

sub pk_name { my ($n) = $other->selectrow_array(q{SELECT TRIM(rdb$constraint_name) FROM rdb$relation_constraints WHERE TRIM(rdb$relation_name) = 'k58_pk' AND rdb$constraint_type = 'PRIMARY KEY'}); $n }
sub relation_count { my ($n) = @_; ($other->selectrow_array(q{SELECT COUNT(*) FROM rdb$relations WHERE TRIM(rdb$relation_name) = ?}, undef, $n))[0] }

my $deploy = DBIO::Firebird::Deploy->new(schema => $schema);
ok eval { $deploy->install; 1 }, 'install' or diag $@;
my $d0 = eval { $deploy->diff };
ok $d0 && !$d0->has_changes, 'the diff after the install is empty' or diag $d0 ? $d0->as_sql : $@;

# a schema that also has a new table, so "before the first statement" is visible
sub fresh { my $s = build_schema([ Pk => 'k58_pk', ['id'] ], [ New => 'k58_new', ['id'] ])->connect($dsn, $user, $pass, {%connect}); push @schemas, $s; DBIO::Firebird::Deploy->new(schema => $s) }

is +(DBIO::Firebird::Introspect->new(dbh => $other)->model->{tables}{k58_pk} // {})->{primary_key_name}, pk_name(),
  'introspection reads the name of the primary key';

for my $case (
  [ 'no primary key', sub { $other->do(sprintf 'ALTER TABLE "k58_pk" DROP CONSTRAINT "%s"', pk_name()) },
    qr/ALTER TABLE "k58_pk" ADD PRIMARY KEY \("id"\);/ ],
  [ 'a key over another column', sub { if (my $n = pk_name()) { $other->do(qq{ALTER TABLE "k58_pk" DROP CONSTRAINT "$n"}) } $other->do(q{ALTER TABLE "k58_pk" ADD PRIMARY KEY ("c")}) },
    qr/ALTER TABLE "k58_pk" DROP CONSTRAINT "INTEG_\d+";.*ADD PRIMARY KEY \("id"\);/s ],
) {
  my ($label, $break, $re) = @$case;
  $break->();
  my $dep = fresh();
  my $d = eval { $dep->diff };
  ok $d && $d->has_changes, "$label: the difference is reported" or diag $@;
  like $d && $d->summary, qr/primary key: k58_pk/, '... in the summary';
  my $sql = eval { $d->as_sql } // '';
  like $sql, $re, '... as_sql writes the statements' or diag $@;
  ok eval { $dep->upgrade; 1 }, '... upgrade is accepted by the server' or diag $@;
  is relation_count('k58_new'), 1, '... the new table beside it is created';
  is_deeply [ map { $_->{column_name} } grep { $_->{is_pk} } @{ DBIO::Firebird::Introspect->new(dbh => $other)->model->{columns}{k58_pk} } ],
    ['id'], '... the key is the schema\'s';
  my $again = eval { $dep->diff };
  ok $again && !$again->has_changes, '... and the diff is empty' or diag $again ? $again->as_sql : $@;
  $other->do('DROP TABLE "k58_new"');
}

cleanup();
$other->disconnect;
done_testing;
