#!/usr/bin/perl

use strict;
use Test::More;
use MyTest::TopNode;

use strict;
plan tests => 9;

# Tests here

is(Class::XML->_gen_search_expr('/', 'foo'), '/foo', "Simple name search");

is(Class::XML->_gen_search_expr('/', { 'bar' => 'baz' }), '/*[@bar = "baz"]',
    "Attribute search only");

is(Class::XML->_gen_search_expr('/', 'foo', { 'bar' => 'baz', 'quux' => 3 }),
   '/foo[@bar = "baz" and @quux = "3"]', "Complex XPath generation");

is(Class::XML->_gen_search_expr('/', 'foo', {}), '/foo', "Empty hash handled");

my $xml =
  qq!<foo><stalk foo="bar" /><spaf foo="bar" /><stalk /><stalk /></foo>!;

my $tree = MyTest::TopNode->new(xml => $xml);

cmp_ok($tree->search_children("stalk"), '==', 3, "Simple search ok");

my ($stalk, $spaf) = $tree->search_children({ 'foo' => 'bar' });

is($stalk->getName, 'stalk', "First child");
is($spaf->getName, 'spaf', "Second child");

is(ref($stalk), "MyTest::MultiChild", "Class bless correct");

cmp_ok($tree->search_children(), '==', 4, "Return all correct");
