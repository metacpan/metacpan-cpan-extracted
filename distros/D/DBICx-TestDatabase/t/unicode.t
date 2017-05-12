#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 5;

use FindBin qw($Bin);
use lib "$Bin/lib";

use DBICx::TestDatabase;

my $schema = DBICx::TestDatabase->connect('MySchema');
ok $schema;
isa_ok $schema, 'MySchema', '$schema';

my $row = $schema->resultset('Foo')->create({ value => 'ñandú' });
ok $row, 'got a row';
is $row->id, 1, 'id 1';

$row =  $schema->resultset('Foo')->find(1);
is( $row->value, 'ñandú', 'Unicode string was retrieved fine');

# it works.
