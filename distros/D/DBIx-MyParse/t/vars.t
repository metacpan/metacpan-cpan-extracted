# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl vars.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 76;

BEGIN {
        use_ok('DBIx::MyParse');
        use_ok('DBIx::MyParse::Query');
        use_ok('DBIx::MyParse::Item')
};

#########################

use strict;

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $parser = DBIx::MyParse->new();

ok(ref($parser) eq 'DBIx::MyParse', 'new_parser');

my $get_user_var1 = $parser->parse('SELECT @a');
my $get_user_var2 = $parser->parse($get_user_var1->print());

foreach my $get_user_var ($get_user_var1,$get_user_var2) {
	ok(ref($get_user_var) eq 'DBIx::MyParse::Query', 'get_user_var1');
	my $items = $get_user_var->getSelectItems();
	ok(ref($items) eq 'ARRAY', 'get_user_var2');
	my $item = $items->[0];
	ok(ref($item) eq 'DBIx::MyParse::Item','get_user_var3');
	ok($item->getType() eq 'FUNC_ITEM','get_user_var4');
	ok($item->getFuncType() eq 'GUSERVAR_FUNC','get_user_var5');
	ok($item->getFuncName() eq 'get_user_var','get_user_var6');
#	ok($item->getAlias() eq '@a','get_user_var7');
	my $arguments = $item->getArguments();
	ok(ref($arguments) eq 'ARRAY','get_user_var8');
	ok(scalar(@{$arguments}) == 1,'get_user_var9');
	my $argument = $arguments->[0];
	ok(ref($argument) eq 'DBIx::MyParse::Item','get_user_var10');
	ok($argument->getType() eq 'USER_VAR_ITEM','get_user_var11');
	ok($argument->getVarName() eq 'a','get_user_var12');
}


my $set_user_var1 = $parser->parse('SELECT @a := 1');
my $set_user_var2 = $parser->parse($set_user_var1->print());

foreach my $set_user_var ($set_user_var1,$set_user_var2) {
	ok(ref($set_user_var) eq 'DBIx::MyParse::Query', 'set_user_var1');
	my $items = $set_user_var->getSelectItems();
	ok(ref($items) eq 'ARRAY', 'set_user_var2');
	my $item = $items->[0];
	ok(ref($item) eq 'DBIx::MyParse::Item','set_user_var3');
	ok($item->getType() eq 'FUNC_ITEM','set_user_var4');
	ok($item->getFuncType() eq 'SUSERVAR_FUNC','set_user_var5');
	ok($item->getFuncName() eq 'set_user_var','set_user_var6');
	my $arguments = $item->getArguments();
	ok(ref($arguments) eq 'ARRAY','set_user_var7');
	ok(scalar(@{$arguments}) == 2,'set_user_var8');
	my $argument1 = $arguments->[0];
	ok(ref($argument1) eq 'DBIx::MyParse::Item','set_user_var9');
	ok($argument1->getType() eq 'USER_VAR_ITEM','set_user_var10');
	ok($argument1->getVarName() eq 'a','set_user_var11');

	my $argument2 = $arguments->[1];
	ok(ref($argument2) eq 'DBIx::MyParse::Item','set_user_var12');
	ok($argument2->getType() eq 'INT_ITEM','set_user_var13');
	ok($argument2->getValue() == 1,'set_user_var12');
}

my $get_system_var1 = $parser->parse('SELECT @@cold_cache.key_cache_block_size');
my $get_system_var2 = $parser->parse($get_system_var1->print());

foreach my $get_system_var ($get_system_var1, $get_system_var2) {
	ok(ref($get_system_var) eq 'DBIx::MyParse::Query', 'get_system_var1');
	my $items = $get_system_var->getSelectItems();
	ok(ref($items) eq 'ARRAY', 'get_system_var');
	my $item = $items->[0];
	ok(ref($item) eq 'DBIx::MyParse::Item','get_system_var3');
	ok($item->getType() eq 'FUNC_ITEM','get_system_var4');
	ok($item->getFuncName() eq 'get_system_var','get_system_var5');
	my $arguments = $item->getArguments();
	ok(ref($arguments) eq 'ARRAY','get_system_var6');
	ok(scalar(@{$arguments}) == 1,'get_system_var7');
	my $argument = $arguments->[0];
	ok(ref($argument) eq 'DBIx::MyParse::Item','get_system_var8');
	ok($argument->getType() eq 'SYSTEM_VAR_ITEM','get_system_var9');
	ok($argument->getVarName() eq 'key_cache_block_size','get_system_var10');
	ok($argument->getVarComponent() eq 'cold_cache','get_system_var11');
}




