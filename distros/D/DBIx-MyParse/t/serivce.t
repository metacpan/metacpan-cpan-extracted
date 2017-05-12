# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl service.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 10;

my $query_class_name = 'DBIx::MyParse::Query';
my $item_class_name = 'DBIx::MyParse::Item';
my $parser_class_name = 'DBIx::MyParse';

use_ok($parser_class_name);
use_ok($query_class_name);
use_ok($item_class_name);

my $parser = DBIx::MyParse->new();
ok(ref($parser) eq $parser_class_name, 'new_parser');

my $repair = $parser->parse("REPAIR TABLE database1.table1");
ok($repair->getCommand() eq 'SQLCOM_REPAIR','repair1');
my $tables1 = $repair->getTables();
ok($tables1->[0]->getTableName() eq 'table1','repair2');
ok($tables1->[0]->getDatabaseName() eq 'database1','repair3');

my $optimize = $parser->parse("OPTIMIZE TABLE database2.table2");
ok($optimize->getCommand() eq 'SQLCOM_OPTIMIZE','optimize1');
my $tables2 = $optimize->getTables();
ok($tables2->[0]->getTableName() eq 'table2','optimize2');
ok($tables2->[0]->getDatabaseName() eq 'database2','optimize3');
