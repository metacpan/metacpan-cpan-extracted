use strict;
use Test::More;
use DBIx::TempDB;

plan skip_all => 'TEST_MYSQL_DSN=mysql://root@127.0.0.1' unless $ENV{TEST_MYSQL_DSN};

my $tmpdb = DBIx::TempDB->new($ENV{TEST_MYSQL_DSN}, auto_create => 1);

eval { $tmpdb->execute_file('affiliate.mysql') };
ok !$@, 'execute_file affiliate.mysql' or diag $@;

done_testing;
