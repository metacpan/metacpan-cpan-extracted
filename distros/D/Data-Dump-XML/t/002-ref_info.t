#!/usr/bin/perl

use Class::Easy;

use Data::Dumper;

use Test::More qw(no_plan);

use_ok 'Data::Dump::XML';
use_ok 'Data::Dump::XML::Parser';

$Class::Easy::DEBUG = 'immediately';

my $dumper = Data::Dump::XML->new;

my $data = {aaa => 'bbb'};

my ($class, $type, $id) = Data::Dump::XML::ref_info ($data);
# diag "class: $class, type: $type, id: $id";
ok $type eq 'HASH';

$data = bless [], 'Foo';

($class, $type, $id) = Data::Dump::XML::ref_info ($data);
diag "class: $class, type: $type, id: $id";
ok $type eq 'ARRAY';
ok $class eq 'Foo';

use Scalar::Util ();

my $t = timer ("Scalar::Util speed test");

for (0 .. 1000) {
	my ($class, $type, $id) = 
		Scalar::Util::blessed ($data),
		Scalar::Util::reftype ($data),
		Scalar::Util::refaddr ($data);
}

$t->lap ("ref_info speed test");

for (0 .. 1000) {
	my ($class, $type, $id) = Data::Dump::XML::ref_info ($data);
}

$t->lap ("Scalar::Util speed test");

for (0 .. 1000) {
	my ($class, $type, $id) = 
		Scalar::Util::blessed ($data),
		Scalar::Util::reftype ($data),
		Scalar::Util::refaddr ($data);
}

$t->lap ("ref_info speed test");

for (0 .. 1000) {
	my ($class, $type, $id) = Data::Dump::XML::ref_info ($data);
}

1;
