#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 5;

use_ok('Data::Identifier');

my $id = Data::Identifier->new(sid => 1);

isa_ok($id, 'Data::Identifier');
isa_ok($id, 'Data::Identifier::Interface::Userdata');

$id->userdata(__PACKAGE__, test => 5);
is($id->userdata(__PACKAGE__, 'test'), 5, 'Reading userdata');

$id = Data::Identifier->new(sid => 2);
ok(!defined($id->userdata(__PACKAGE__, 'test')), 'Reading userdata (negative)');

exit 0;
