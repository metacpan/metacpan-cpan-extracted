use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k45). SYSCAT.COLUMNS.LENGTH of a DECFLOAT column is the
# storage length, 8 or 16 bytes, for DECFLOAT(16) and DECFLOAT(34). Rendered
# as it stood, the diff wrote DECFLOAT(16) for a DECFLOAT(34) -- silently the
# smaller type -- and DECFLOAT(8), which the server refuses (SQL0604N).
# Everything runs through the public DBIO::DB2::Deploy API, plus one read of
# the introspected model.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $TABLE = "dbio_k45_$$";

{
  package DBIO::Test::K45::Item;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k45_$$");
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    d16   => { data_type => 'decfloat', size => 16, is_nullable => 1 },
    d34   => { data_type => 'decfloat', size => 34, is_nullable => 1 },
    dbare => { data_type => 'decfloat', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIO::Test::K45::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Item => 'DBIO::Test::K45::Item');
}

use DBIO::DB2::Deploy;

my $schema = DBIO::Test::K45::Schema->connect($dsn, $user, $pass);

my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

sub drop_test_table {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP TABLE "$TABLE"}) };
}

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
sub compare_schema_count {
  my ($n) = $dbh->selectrow_array(
    'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA);
  return $n;
}

END {
  if ($dbh && $dbh->{Active}) {
    drop_test_table();
    $deploy->_drop_test_schema($dbh, $COMPARE_SCHEMA)
      if eval { compare_schema_count() };
  }
}

drop_test_table();

lives_ok { $deploy->install } 'install deploys DECFLOAT(16), DECFLOAT(34) and a bare DECFLOAT';

my $model = $deploy->_introspect_current;
my %col = map { $_->{column_name} => $_ } @{ $model->{columns}{$TABLE} // [] };

is $col{d16}{data_type}, 'decfloat', 'introspected as decfloat';
is $col{d16}{size}, 16, 'DECFLOAT(16): size 16 in the model';
is $col{d34}{size}, 34, 'DECFLOAT(34): size 34 in the model';
is $col{dbare}{size}, 34, 'a bare DECFLOAT is DECFLOAT(34) in the model';

{
  my $diff = eval { $deploy->diff };
  ok $diff, 'diff after install' or diag $@;
  my @ops = $diff ? @{ $diff->operations } : (1);
  is scalar(@ops), 0, 'follow-up diff is empty'
    or diag join "\n", map { ref $_ ? $_->as_sql : $_ } @ops;
}

done_testing;
