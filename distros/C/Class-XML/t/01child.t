#!/usr/bin/perl

use strict;
use Test::More;
use MyTest::TopNode;

use strict;
plan tests => 13;

# Tests here

my $xml = qq!<foo><bar /></foo>!;

my $tree = MyTest::TopNode->new( xml => $xml);

isa_ok($tree, 'MyTest::TopNode', "Tree object");
can_ok($tree, 'bar');

is ("${tree}", $xml, "Stringify tree");

my $child = $tree->bar;

is ("${child}", "<bar />", "Got child node");

my $parent = $child->foo;

is ("${parent}", $xml, "Return to parent");

eval { $child->foo(3); };

like ($@, qr/^'Class::XML' cannot alter the value of 'foo' on objects of class 'MyTest::SingleChild'/, "Read-only parent property");

my $bad_tree = MyTest::TopNode->new( xml => qq!<foo><bar /><bar /></foo>! );

eval { $bad_tree->bar; };

like ($@, qr/^Multiple bar children \(2\) found for has_child relation of MyTest::TopNode/, "Multiple children trapped");

eval { $tree->bar( 'dummy' ); };

like ($@, qr/^New bar is not an XPath node/, "Incorrect type trapped");

eval { $tree->bar( XML::XPath::Node::Element->new("wrong") ); };

like ($@, qr/^Incorrect node name wrong \(expected bar\)/, "Incorrect node name trapped");

my $new_child = MyTest::SingleChild->new("bar");

$new_child->counter('formica');

is ("${new_child}", qq!<bar counter="formica" />!, "New child created correctly");

$tree->bar($new_child);

is ("${tree}", qq!<foo><bar counter="formica" /></foo>!, "New child added correctly as replacement");

$tree->bar( undef );

is ("${tree}", qq!<foo />!, "Child deleted correctly");

$tree->bar($new_child);

is ("${tree}", qq!<foo><bar counter="formica" /></foo>!, "New child added correctly as new");
