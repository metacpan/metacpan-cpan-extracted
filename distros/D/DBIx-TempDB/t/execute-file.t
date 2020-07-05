use strict;
use Test::More;
use DBIx::TempDB;

my $tmpdb = DBIx::TempDB->new('postgresql://example.com', auto_create => 0);
my $sql;
no warnings 'redefine';
*DBIx::TempDB::execute = sub { $sql = pop };

$tmpdb->execute_file("users.sql");
like $sql, qr{create table}, 'execute_file()';

done_testing;
