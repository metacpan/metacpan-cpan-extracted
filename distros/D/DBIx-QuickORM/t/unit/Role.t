# Test origin: AI
use Test2::V0;

use DBIx::QuickORM;
use DBIx::QuickORM::Role;

is($DBIx::QuickORM::Role::VERSION, $DBIx::QuickORM::VERSION, "The namespace package loads and carries the distribution version");

done_testing;
