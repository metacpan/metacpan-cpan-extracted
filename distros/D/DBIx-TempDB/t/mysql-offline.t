use strict;
use Test::More;
use DBIx::TempDB;

my $tmpdb = DBIx::TempDB->new('mysql://example.com', auto_create => 0, database_name => 'foo');

is $tmpdb->url, 'mysql://example.com', 'url';

is_deeply(
  [$tmpdb->dsn],
  [
    'dbi:mysql:host=example.com;database=foo',
    undef, undef, {AutoCommit => 1, AutoInactiveDestroy => 1, PrintError => 0, RaiseError => 1, mysql_enable_utf8 => 1}
  ],
  'dsn for foo'
);

$tmpdb = DBIx::TempDB->new('mysql://u:p@127.0.0.1:1234?AutoCommit=0', auto_create => 0, database_name => 'yikes');
is_deeply(
  [$tmpdb->dsn],
  [
    'dbi:mysql:host=127.0.0.1;port=1234;database=yikes',
    'u', 'p', {AutoCommit => 0, AutoInactiveDestroy => 1, PrintError => 0, RaiseError => 1, mysql_enable_utf8 => 1}
  ],
  'dsn for yikes'
);

done_testing;
