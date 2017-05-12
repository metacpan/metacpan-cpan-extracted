use strict;
BEGIN {
  use Test::More;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_XBASE}) {
    plan skip_all => 'TEST_XBASE not configured';
  } else {
    plan tests => 26;
  }
  use_ok('DBIx::PgLink::Adapter::XBase');
}

use Data::Dumper;

my $db = DBIx::PgLink::Adapter::XBase->new();
ok($db, 'adapter instance created');

can_ok($db, 'connect', 'install_roles', 'prepare', 'ping', 'table_info', 'column_info');


ok( 
  $db->connect('dbi:XBase:examples', undef, undef, {RaiseError=>1}),
  'adapter connected'
);
ok(defined $db->dbh, 'attribute dbh exists');

is($db->quote_identifier(q!foo!), q!foo!, "quote_identifier");
is($db->quote_identifier(q!foo.bar!), q!foo.bar!, "quote_identifier");
is($db->quote_identifier(q!"foo.bar"!), q!"foo.bar"!, "quote_identifier");
is($db->quote_identifier(q!foo.dbf!), q!foo.dbf!, "quote_identifier");
is($db->quote_identifier(q!foo!, q!bar!), q!bar!, "quote_identifier");

{
  my $sth = $db->prepare("SELECT * FROM crud WHERE ID = ?");
  ok($sth, 'statement prepared');
  ok($sth->execute(1), 'statement executed');
  my @arr = $sth->fetchrow_array;
  is_deeply(\@arr, [1, 1, 'row#1'], 'got the right value');
}

{
  my $sth = $db->table_info('%', '%', '%', 'TABLE');
  my $data = $sth->fetchall_hashref('TABLE_NAME');
  diag Dumper($data) if $Trace_level;
  my @keys = sort keys %{$data};
  is_deeply( \@keys, [qw/all_types cp866 crud date_u/], 'tables found');
}

{
  my $sth = $db->column_info('%', '%', 'all_types', '%');
  my $data = $sth->fetchall_arrayref({});
  diag Dumper($data) if $Trace_level;
  is($data->[0]->{COLUMN_NAME}, 'C', 'column found');
  is($data->[0]->{TYPE_NAME},   'CHAR', 'type found');
  is($data->[1]->{COLUMN_NAME}, 'N', 'column found');
  is($data->[1]->{TYPE_NAME},   'NUMERIC', 'type found');
  is($data->[2]->{COLUMN_NAME}, 'F', 'column found');
  is($data->[2]->{TYPE_NAME},   'FLOAT', 'type found');
  is($data->[3]->{COLUMN_NAME}, 'D', 'column found');
  is($data->[3]->{TYPE_NAME},   'DATE', 'type found');
  is($data->[4]->{COLUMN_NAME}, 'L', 'column found');
  is($data->[4]->{TYPE_NAME},   'BOOLEAN', 'type found');
  is($data->[5]->{COLUMN_NAME}, 'M', 'column found');
  is($data->[5]->{TYPE_NAME},   'BLOB', 'type found');
}
