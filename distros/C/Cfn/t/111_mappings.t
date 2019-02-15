#!/usr/bin/env perl

use strict;
use warnings;
use Data::Printer;
use Test::More;

use Cfn;

my $obj = Cfn->new;

$obj->addMapping(Map1 => {
  key1 => 'value1',
});

$obj->addMapping(Map2 => {
  key2 => 'value2',
});

isa_ok($obj->Mapping('Map1'), 'Cfn::Mapping');

my $struct = $obj->as_hashref;

cmp_ok($struct->{Mappings}{Map1}{key1}, 'eq', 'value1', 'Got a value for a key on Map1');
cmp_ok($struct->{Mappings}{Map2}{key2}, 'eq', 'value2', 'Got a value for a key on Map2');

eval {
  $obj->addMapping('Map1', { 'x' => 1 });
};
like($@, qr/A mapping named Map1 already exists/, 'Stack with a duplicate mapping throws');

done_testing;
