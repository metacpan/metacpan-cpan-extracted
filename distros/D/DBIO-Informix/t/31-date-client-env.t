use strict;
use warnings;

use Test::More;
use DBIO::Optional::Dependencies ();
use DBIO::Test;
use Scope::Guard ();
use DBI ();

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_dt')
. ' and ' .
DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_informix')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_dt')
    && DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_informix');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_INFORMIX_DSN} _USER and _PASS to run this test'
  unless $dsn;

# The Informix client formats and parses DATE by DBDATE, DBCENTURY and GL_DATE
# at the time it connects. A DATE must come back as the day it went in,
# whatever the caller's environment holds: a day under 13 is the case where a
# wrong order stores another date without an error, a day above 12 the case
# where it is refused.

my @ENVS = (
  [ 'DBDATE=DMY4.'  => { DBDATE => 'DMY4.' } ],
  [ 'DBDATE=Y4MD-'  => { DBDATE => 'Y4MD-' } ],
  [ 'DBDATE=MDY4/'  => { DBDATE => 'MDY4/' } ],
  [ 'DBDATE=DMY2/ DBCENTURY=F' => { DBDATE => 'DMY2/', DBCENTURY => 'F' } ],
  [ 'GL_DATE=%d.%m.%Y' => { GL_DATE => '%d.%m.%Y' } ],
  [ 'no DBDATE' => {} ],
);
my @DAYS = ([2026, 11, 9], [2026, 11, 25]);

my $table = 'dbio_ix_dateenv';
my $guard = Scope::Guard->new(sub {
  my $dbh = eval { DBI->connect($dsn, $user, $pass, { PrintError => 0, RaiseError => 0 }) } or return;
  eval { $dbh->do("DROP TABLE $table") };
});

for my $case (@ENVS) {
  my ($label, $env) = @$case;

  local %ENV = %ENV;
  delete @ENV{qw(DBDATE DBCENTURY GL_DATE)};
  @ENV{keys %$env} = values %$env;

  my $declared = DBIO::Test::Schema->clone(storage_type => q{+DBIO::Informix::Storage});
  my $schema = $declared->connect($dsn, $user, $pass, {
    on_connect_call => [ 'datetime_setup' ],
  });
  my $dbh = $schema->storage->dbh;

  eval { $dbh->do("DROP TABLE $table") };
  $dbh->do("CREATE TABLE $table (id INT PRIMARY KEY, starts_at DATE)");

  my $id = 0;
  for my $ymd (@DAYS) {
    my ($y, $m, $d) = @$ymd;
    my $date = DateTime->new(year => $y, month => $m, day => $d);
    $id++;

    $dbh->do("INSERT INTO $table (id, starts_at) VALUES (?, ?)", undef,
      $id, $schema->storage->datetime_parser->format_date($date));

    my ($sm, $sd) = $dbh->selectrow_array(
      "SELECT MONTH(starts_at), DAY(starts_at) FROM $table WHERE id = ?", undef, $id);
    is "$sm-$sd", "$m-$d", "$label: day $d stored as that day, not as another date";

    my ($raw) = $dbh->selectrow_array(
      "SELECT starts_at FROM $table WHERE id = ?", undef, $id);
    my $back = eval { $schema->storage->datetime_parser->parse_date($raw) };
    is $back, $date, "$label: day $d reads back as the same DateTime"
      or diag "client returned '" . ($raw // 'undef') . "'";
  }

  eval { $dbh->do("DROP TABLE $table") };
  $schema->storage->disconnect;
}

done_testing;
