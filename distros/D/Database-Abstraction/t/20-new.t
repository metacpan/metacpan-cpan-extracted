#!perl -wT

use strict;
use File::Spec;

use lib 't/lib';
use Test::Most tests => 5;

use_ok('Database::Abstraction::Test');
use_ok('Database::Abstraction::Error');

my $tmpdir = File::Spec->tmpdir();

isa_ok(Database::Abstraction::Test->new($tmpdir), 'Database::Abstraction::Test', 'Creating Database::Abstraction::Test object');
isa_ok(Database::Abstraction::Test->new({ directory => $tmpdir }), 'Database::Abstraction::Test', 'Creating Database::Abstraction::Test object');
isa_ok(Database::Abstraction::Test->new(directory => $tmpdir), 'Database::Abstraction::Test', 'Creating Database::Abstraction::Test object');
# FIXME: Use of inherited AUTOLOAD for non-method Database::Abstraction::Test::new() is no longer allowed
# isa_ok(Database::Abstraction::Test::new('/'), 'Database::Abstraction::Test', 'Creating Database::Abstraction::Test object');
# ok(!defined(Database::Abstraction::Test::new()));
