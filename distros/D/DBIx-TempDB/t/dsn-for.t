use strict;
use Test::More;
use DBIx::TempDB::Util 'dsn_for';

my @tests = (
  'postgresql://postgres@localhost/my_db',
  [
    'dbi:Pg:host=localhost;dbname=my_db',
    'postgres', undef, {AutoCommit => 1, AutoInactiveDestroy => 1, PrintError => 0, RaiseError => 1}
  ],
  'postgresql://pg:s3cret@localhost?AutoInactiveDestroy=0',
  [
    'dbi:Pg:host=localhost', 'pg', 's3cret',
    {AutoCommit => 1, AutoInactiveDestroy => 0, PrintError => 0, RaiseError => 1}
  ],
  'mysql://root@127.0.0.1',
  [
    'dbi:mysql:host=127.0.0.1', 'root', undef,
    {AutoCommit => 1, AutoInactiveDestroy => 1, PrintError => 0, RaiseError => 1, mysql_enable_utf8 => 1}
  ],
  'mysql://u1:s3cret@localhost?PrintError=1',
  [
    'dbi:mysql:host=localhost', 'u1', 's3cret',
    {AutoCommit => 1, AutoInactiveDestroy => 1, PrintError => 1, RaiseError => 1, mysql_enable_utf8 => 1}
  ],
  'mysql://x:y@example.com:2345/aiaiai',
  [
    'dbi:mysql:host=example.com;port=2345;database=aiaiai',
    'x', 'y', {AutoCommit => 1, AutoInactiveDestroy => 1, PrintError => 0, RaiseError => 1, mysql_enable_utf8 => 1}
  ],
);

while (@tests) {
  my $url = shift @tests;
  my $exp = shift @tests;

  is_deeply [dsn_for($url)], $exp, $url;
  is_deeply [dsn_for(URI::db->new($url))], $exp, $url;
}

done_testing;
