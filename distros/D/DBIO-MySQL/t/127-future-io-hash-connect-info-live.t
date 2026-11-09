use strict;
use warnings;
use Test::More;

# LIVE proof of karr k66: the DBD attributes of the single-hash connect form
# (connect({ dsn, user, password, <attr> => ..., async => 'future_io' })) are
# on the pool connection's handle, the very values the owner's handle has.
# t/126 pins the reading offline over a fake DBI->connect; which attributes a
# real DBD takes and keeps on the handle is only known here.
#
# Runs through whichever DBD the DSN names; needs DBIO_TEST_MYSQL_DSN, _USER
# and _PASS. Creates nothing on the server.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

eval { require DBIO::MySQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

my ($dbd) = $dsn =~ /\Adbi:(\w+):/;
plan skip_all => 'DBIO_TEST_MYSQL_DSN names neither dbi:mysql: nor dbi:MariaDB:'
  unless defined $dbd && $dbd =~ /\A(?:mysql|MariaDB)\z/;
my $prefix = lc $dbd;

require DBIO::Test;
my $test_schema = DBIO::Test::Schema->clone;
$test_schema->storage_type(
  $dbd eq 'MariaDB' ? '+DBIO::MySQL::Storage::MariaDB' : '+DBIO::MySQL::Storage'
);

# server_prepare is stored on the handle by both DBDs and is off by default;
# use_result is a second one, off by default.
my %want = ("${prefix}_server_prepare" => 1, "${prefix}_use_result" => 1);

my $schema = $test_schema->connect({
  dsn => $dsn, user => $user, password => $pass,
  %want, async => 'future_io', pool_size => 1,
});
my $owner = $schema->storage->dbh;
my $async = $schema->storage->async;
my $conn  = $async->pool->acquire->get;
my $pdbh  = $conn->{dbh};

for my $attr (sort keys %want) {
  is $owner->{$attr}, $want{$attr}, "owner handle: $attr";
  is $pdbh->{$attr},  $want{$attr}, "pool handle: $attr, as the owner's";
}

$async->pool->release($conn) if $async->pool->can('release');
$schema->storage->disconnect;
done_testing;
