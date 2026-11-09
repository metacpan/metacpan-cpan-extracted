use strict;
use warnings;

use Test::More;
use DBIO::Optional::Dependencies ();
use DBIO::Test;
use Scope::Guard ();

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_dt')
. ' and ' .
DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_informix')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_dt')
    && DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_informix');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_${_}" } qw/DSN USER PASS/};

if (not $dsn) {
  plan skip_all => <<'EOF';
Set $ENV{DBIO_TEST_INFORMIX_DSN} _USER and _PASS to run this test'.
Warning: This test drops and creates a table called 'event'";
EOF
}

my $schema;

{
  # A schema always has a driver (core ADR 0067): declare it on a clone.
  my $declared = DBIO::Test::Schema->clone(storage_type => q{+DBIO::Informix::Storage});
  $schema = $declared->connect($dsn, $user, $pass, {
    on_connect_call => [ 'datetime_setup' ],
  });

  my $sg = Scope::Guard->new(sub { cleanup($schema) } );

  eval { $schema->storage->dbh->do('DROP TABLE event') };
  $schema->storage->dbh->do(<<'SQL');
  CREATE TABLE event (
    id INT PRIMARY KEY,
    starts_at DATE,
    created_on DATETIME YEAR TO FRACTION(5)
  );
SQL
  my $rs = $schema->resultset('Event');

  my $dt = DateTime->now;
  $dt->set_nanosecond(555640000);

  my $date_only = DateTime->new(
    year => $dt->year, month => $dt->month, day => $dt->day
  );

  my $row;
  ok( $row = $rs->create({
    id => 1,
    starts_at => $date_only,
    created_on => $dt,
  }));
  ok( $row = $rs->search({ id => 1 }, { select => [qw/starts_at created_on/] })
    ->first
  );
  is $row->created_on, $dt, 'TIMESTAMP as DateTime roundtrip';

  cmp_ok $row->created_on->nanosecond, '==', $dt->nanosecond,
    'fractional part of a second survived';

  is $row->starts_at, $date_only, 'DATE as DateTime roundtrip';
}

done_testing;

# clean up our mess
sub cleanup {
  my $schema = shift;
  my $dbh;
  eval {
    # a cached statement of the test still has the table open (-242,
    # non-exclusive access): drop it on a fresh connection
    $schema->storage->disconnect;
    $dbh = $schema->storage->dbh;
  };
  return unless $dbh;

  eval { $dbh->do(qq{DROP TABLE $_}); 1 } or warn "cleanup: $@" for qw/event/;
}
