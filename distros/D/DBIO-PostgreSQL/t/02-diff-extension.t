use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Extension;

my @ops = DBIO::PostgreSQL::Diff::Extension->diff(
  {},
  { pgcrypto => { extension_name => 'pgcrypto', version => '1.3' } },
);

is(scalar @ops, 1, 'one extension to create');
is($ops[0]->action, 'create', 'action is create');
like($ops[0]->as_sql, qr/CREATE EXTENSION.*pgcrypto/, 'DDL is correct');

@ops = DBIO::PostgreSQL::Diff::Extension->diff(
  { pgcrypto => { extension_name => 'pgcrypto', version => '1.3' } },
  { pgcrypto => { extension_name => 'pgcrypto', version => '1.4' } },
);

is(scalar @ops, 1, 'one extension to update');
is($ops[0]->action, 'update', 'action is update');
like($ops[0]->as_sql, qr/ALTER EXTENSION pgcrypto UPDATE TO '1.4'/, 'DDL is correct');

@ops = DBIO::PostgreSQL::Diff::Extension->diff(
  { pgcrypto => { extension_name => 'pgcrypto', version => '1.3' } },
  {},
);

is(scalar @ops, 1, 'one extension to drop');
is($ops[0]->action, 'drop', 'action is drop');

done_testing;
