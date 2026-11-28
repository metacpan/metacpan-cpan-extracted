# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Dialect::MariaDB;

my $D = 'DBIx::QuickORM::Dialect::MariaDB';

isa_ok($D, ['DBIx::QuickORM::Dialect::MySQL'], "Shares MySQL's behavior");
is($D->supports_returning_insert,         1,                  "RETURNING on INSERT");
is($D->supports_returning_update,         0,                  "No RETURNING on UPDATE");
is($D->supports_returning_delete,         1,                  "RETURNING on DELETE");
is($D->quote_char,                        '`',                "Backtick quoting from MySQL");
is($D->error_kind(4025, 'HY000', 'text'), 'check_violation',  "MariaDB's CHECK code");
is($D->error_kind(3819, 'HY000', 'text'), undef,              "not MySQL's");
is($D->error_kind(1062, '23000', 'text'), 'unique_violation', "The rest are MySQL's");

done_testing;
