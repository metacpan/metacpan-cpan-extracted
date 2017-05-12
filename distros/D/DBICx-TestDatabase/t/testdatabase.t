#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 5;

use FindBin qw($Bin);
use lib "$Bin/lib";

use DBICx::TestDatabase;

my $schema = DBICx::TestDatabase->connect('MySchema');
ok $schema;
isa_ok $schema, 'MySchema', '$schema';

my $row = $schema->resultset('Foo')->create({ value => 'foo' });

ok $row, 'got a row';
is $row->id, 1, 'id 1';

$schema->resultset('Foo')->create({ value => 'bar' });
my $second = $schema->resultset('Foo')->search({ value => 'bar' })->first;

is $second->id, 2, 'got second row';

# it works.
