#!perl -w

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 3;

use_ok('Database::test1');

Database::Abstraction::init({ directory => 'xyzzy' });

my $defaults = Database::Abstraction::init();
cmp_ok($defaults->{'directory'}, 'eq', 'xyzzy', 'init() with no args works');
cmp_ok($Database::Abstraction::{'defaults'}{'directory'}, 'eq', 'xyzzy', 'Class level defaults work');
