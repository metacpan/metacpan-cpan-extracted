#!perl -w

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 6;

use_ok('Database::test1');

Database::Abstraction::init({ directory => 'xyzzy' });

my $defaults = Database::Abstraction::init();
cmp_ok($defaults->{'directory'}, 'eq', 'xyzzy', 'init() with no args works');
cmp_ok($Database::Abstraction::{'defaults'}{'directory'}, 'eq', 'xyzzy', 'Class level defaults work');

# Passing a hash reference with some overrides
$defaults = Database::Abstraction::init({ directory => '/new/path', cache_duration => 600 });
cmp_ok($defaults->{'directory'}, 'eq', '/new/path', 'hash reference works');

# Passing key-value pairs directly
$defaults = Database::Abstraction::init(directory => '/another/path', cache => 0);
cmp_ok($defaults->{'directory'}, 'eq', '/another/path', 'key-value pair works');

# Empty hash reference, should retain defaults
$defaults = Database::Abstraction::init({});
cmp_ok($defaults->{'directory'}, 'eq', '/another/path', 'empty hash keeps previous values');
