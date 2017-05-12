use strict;
use Data::Dumper;
use Test::More tests => 3;

use_ok('Anarres::Mud::Driver::Compiler');

my $compiler = new Anarres::Mud::Driver::Compiler;
ok(defined($compiler), 'We constructed something ...');
ok(ref($compiler) =~ m/::Compiler$/, '... which looks like a compiler');
