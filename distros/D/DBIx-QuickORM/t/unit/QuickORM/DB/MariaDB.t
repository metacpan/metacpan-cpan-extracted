use Test2::Require::Module 'DBD::MariaDB';
use Test2::Require::Module 'DateTime::Format::MySQL';
use Test2::V0 -target => 'DBIx::QuickORM::DB::MariaDB';

use ok $CLASS;

done_testing;
