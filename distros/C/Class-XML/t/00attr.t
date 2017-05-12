#!/usr/bin/perl

use strict;
use Test::More;
use MyTest::HasAttrs;

use strict;
plan tests => 9;

# Tests here

my $xml = qq!<bibble colour="pink" flavour="mango" length="3m" />!;

my $tree = MyTest::HasAttrs->new( xml => $xml);

isa_ok($tree, 'MyTest::HasAttrs', "Tree object");
can_ok($tree, 'length', 'colour', 'flavour');
is($tree->length, '3m', "Length correct");
is($tree->colour , 'pink', "Colour correct");
is($tree->flavour,  'mango', "Flavour correct");
is("${tree}", $xml, "Stringify correct");

$tree->colour("purple");

is($tree->colour, 'purple', "Colour mutated correctly");

my $mutated_xml = $xml;
$mutated_xml =~ s/pink/purple/;

is("${tree}", $mutated_xml, "Stringify after mutation correct");

$tree->length(undef);

$mutated_xml =~ s/ length="3m"//;

is("${tree}", $mutated_xml, "Attribute deletion correct");
