use strict;
use Test::More;
use DBIx::TempDB;
use Data::Dumper;

my $tmpdb = DBIx::TempDB->new('postgresql://example.com', auto_create => 0, database_name => 'foo');

is $tmpdb->url, 'postgresql://example.com', 'url';

is_deeply(
  [$tmpdb->dsn],
  [
    'dbi:Pg:host=example.com;dbname=foo',
    undef, undef, {AutoCommit => 1, AutoInactiveDestroy => 1, PrintError => 0, RaiseError => 1}
  ],
  'dsn for foo'
);

$tmpdb = DBIx::TempDB->new('postgresql://u:p@127.0.0.1:1234?AutoCommit=0', auto_create => 0, database_name => 'yikes');
is_deeply(
  [$tmpdb->dsn],
  [
    'dbi:Pg:host=127.0.0.1;port=1234;dbname=yikes',
    'u', 'p', {AutoCommit => 0, AutoInactiveDestroy => 1, PrintError => 0, RaiseError => 1}
  ],
  'dsn for tikes'
);

done_testing;
