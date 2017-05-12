use strict;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl extract.t'

#########################

use Test::More tests => 13;

BEGIN { use_ok('DBIx::MyParsePP') };
BEGIN { use_ok('DBIx::MyParsePP::Query') };
BEGIN { use_ok('DBIx::MyParsePP::Rule') };
BEGIN { use_ok('DBIx::MyParsePP::Token') };

my $query_class = 'DBIx::MyParsePP::Query';
my $rule_class = 'DBIx::MyParsePP::Rule';
my $token_class = 'DBIx::MyParsePP::Token';

my $parser = DBIx::MyParsePP->new();

my $query = $parser->parse("SELECT a + b, c.d ");
ok(defined $query, 'extract1');

ok(ref($query) eq $query_class,'extract2');
my $select_item_list = $query->extract('select_item_list');
ok(ref($select_item_list) eq $rule_class,'extract3');

my $select_items = $select_item_list->extract('select_item');
ok(ref($select_items) eq 'ARRAY', 'extract4');
my @select_items = @{$select_items};
ok($#select_items == 1, 'extract5');

my $tables = $select_item_list->extract('simple_ident');
ok(ref($tables) eq 'ARRAY', 'extract6');
my @tables = @{$tables};
ok($#tables == 2, 'extract7');

my $idents = $select_item_list->extract('IDENT');
my @idents = @{$idents};

#
# Test for non-existing name
#

my $bogus = $query->extract('bogus');
ok(!defined $bogus, 'extract8');


# This is a test to make sure that in case of nested operators
# only the top-level is returned. Even though there are many
# expressions in this query, calling extract("expr") on the top-level
# rule should only return the top two of them.

my $sum_query = $parser->parse("SELECT ((1+2) + (2+3)) + (3+4)");
my $expr_list = $sum_query->extract("expr");
my @expr_list = @{$expr_list};
ok($#expr_list = 1, 'extract9');
