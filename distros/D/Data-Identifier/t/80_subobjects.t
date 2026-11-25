#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 6;

use_ok('Data::Identifier::Interface::Subobjects');

my $parent = Data::Identifier::Interface::Subobjects->so_new;
isa_ok($parent, 'Data::Identifier::Interface::Subobjects');

my $so = Data::Identifier::Interface::Subobjects->so_new;
isa_ok($so, 'Data::Identifier::Interface::Subobjects');

$so->so_attach(parent => $parent);
is($so->so_get('parent'), $parent, 'Parent readback (strong)');

$so->so_attach(parent => $parent, weak => 1);
is($so->so_get('parent'), $parent, 'Parent readback (weak)');

$parent = undef;
ok(!defined($so->so_get('parent', default => undef)), 'Parent readback (gone)');

exit 0;
