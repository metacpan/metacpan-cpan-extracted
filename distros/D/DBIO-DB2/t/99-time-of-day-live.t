use strict;
use warnings;

use Test::More;
use DBIO::Optional::Dependencies ();

# LIVE ONLY. A `time` column with inflate_datetime is written and read through
# DBIO::InflateColumn::DateTime and the storage's parser. The server decides
# what was stored: HOUR(), MINUTE() and SECOND() of the column. Offline
# counterpart: t/98.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

use DateTime;

my $TABLE = "dbio_k99t_$$";

{
  package DBIO::Test::K99T::Item;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('InflateColumn::DateTime');
  __PACKAGE__->table("dbio_k99t_$$");
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    at => { data_type => 'time', inflate_datetime => 1, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIO::Test::K99T::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Item => 'DBIO::Test::K99T::Item');
}

my $schema = DBIO::Test::K99T::Schema->connect($dsn, $user, $pass);
my $dbh = $schema->storage->dbh;
$dbh->do(qq{CREATE TABLE "$TABLE" ("id" INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY, "at" TIME)});

eval {
  my $rs = $schema->resultset('Item');
  my $row = $rs->create({ at => DateTime->new(year => 2026, month => 10, day => 25,
    hour => 15, minute => 14, second => 15, nanosecond => 5, time_zone => 'floating') });

  my ($h, $m, $s) = $dbh->selectrow_array(
    qq{SELECT HOUR("at"), MINUTE("at"), SECOND("at") FROM "$TABLE" WHERE "id" = ?}, undef, $row->id);
  is_deeply [$h, $m, $s], [15, 14, 15], 'the server stored 15:14:15';

  my $back = $rs->find($row->id)->at;
  isa_ok $back, 'DateTime';
  is $back->ymd, '1970-01-01', 'read back on 1970-01-01';
  is $back->hms, '15:14:15', 'read back as the same time of day';

  $rs->find($row->id)->update({ at => DateTime->new(year => 1970, month => 1, day => 1,
    hour => 0, minute => 0, second => 0) });
  is $rs->find($row->id)->at->hms, '00:00:00', 'midnight round-trips';
};
my $err = $@;
$dbh->do(qq{DROP TABLE "$TABLE"});
die $err if $err;

done_testing;
