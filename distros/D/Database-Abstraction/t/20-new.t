#!perl -wT

use strict;
use File::Spec;

use lib 't/lib';
use Test::Most tests => 4;

use_ok('Database::test1');

my $tmpdir = File::Spec->tmpdir();

isa_ok(Database::test1->new($tmpdir), 'Database::test1', 'Creating Database::test1 object');
isa_ok(Database::test1->new({ directory => $tmpdir }), 'Database::test1', 'Creating Database::test1 object');
isa_ok(Database::test1->new(directory => $tmpdir), 'Database::test1', 'Creating Database::test1 object');
# FIXME: Use of inherited AUTOLOAD for non-method Database::test1::new() is no longer allowed
# isa_ok(Database::test1::new('/'), 'Database::test1', 'Creating Database::test1 object');
# is_ok(Database::test1::new()));
