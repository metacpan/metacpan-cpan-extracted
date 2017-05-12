#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;

use FindBin qw($Bin);
use lib "$Bin/lib";

use TestDatabase;

my $schema = TestDatabase->connect;
isa_ok $schema, 'TestDatabase', '$schema';
isa_ok $schema, 'MySchema', '$schema';

ok $schema->{_tmpfile}, 'got a _tmpfile';

my $row = $schema->resultset('Foo')->create({ value => 'bar' });
ok $row, 'got a row';
is $row->id, 1, 'row id is 1';

is $schema->foo, 'foo', 'foo method works';
