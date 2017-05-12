use strict;
use Data::Dumper;
use Test::More tests => 8;

use_ok('Anarres::Mud::Driver::Compiler::Node');
use_ok('Anarres::Mud::Driver::Compiler::Dump');
use_ok('Anarres::Mud::Driver::Compiler::Check');
use_ok('Anarres::Mud::Driver::Compiler::Generate');

my $nil = new Anarres::Mud::Driver::Compiler::Node::Nil;
ok($nil, 'Created a new Nil');
ok($nil->dump =~ /nil/, 'Nil dumps (nil)');
ok($nil->check, 'Nil checks (1)');	# Cheat on the args!
ok($nil->generate =~ /undef/, 'Nil generates (undef)');
