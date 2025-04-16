#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 2 + 4*3 + 7;

use_ok('Data::Identifier');
use_ok('Data::Identifier::Cloudlet');

my $cl;

$cl = Data::Identifier::Cloudlet->new(root => Data::Identifier->new(sid => 1));
isa_ok($cl, 'Data::Identifier::Cloudlet');
is(scalar($cl->roots), 1, 'Number of root tags');
is(scalar($cl->entries), 1, 'Number of entry tags');

$cl = Data::Identifier::Cloudlet->new(root => Data::Identifier->new(sid => 1), entry => Data::Identifier->new(sid => 2));
isa_ok($cl, 'Data::Identifier::Cloudlet');
is(scalar($cl->roots), 1, 'Number of root tags');
is(scalar($cl->entries), 2, 'Number of entry tags');

$cl = Data::Identifier::Cloudlet->new(root => Data::Identifier->new(sid => 1), entry => Data::Identifier->new(sid => 1));
isa_ok($cl, 'Data::Identifier::Cloudlet');
is(scalar($cl->roots), 1, 'Number of root tags');
is(scalar($cl->entries), 1, 'Number of entry tags');

$cl = Data::Identifier::Cloudlet->new(root => [Data::Identifier->new(sid => 1), Data::Identifier->new(sid => 2)]);
isa_ok($cl, 'Data::Identifier::Cloudlet');
is(scalar($cl->roots), 2, 'Number of root tags');
is(scalar($cl->entries), 2, 'Number of entry tags');

$cl = Data::Identifier::Cloudlet->new(root => Data::Identifier->new(sid => 1), entry => Data::Identifier->new(sid => 2));
isa_ok($cl, 'Data::Identifier::Cloudlet');
ok( $cl->is_root( Data::Identifier->new(sid => 1)), 'Is root positive');
ok(!$cl->is_root( Data::Identifier->new(sid => 2)), 'Is root negative');
ok(!$cl->is_root( Data::Identifier->new(sid => 3)), 'Is root negative');
ok( $cl->is_entry(Data::Identifier->new(sid => 1)), 'Is is entry positive');
ok( $cl->is_entry(Data::Identifier->new(sid => 2)), 'Is is entry positive');
ok(!$cl->is_entry(Data::Identifier->new(sid => 3)), 'Is is entry negative');

exit 0;
