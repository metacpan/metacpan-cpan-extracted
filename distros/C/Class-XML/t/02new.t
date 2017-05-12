#!/usr/bin/perl

use strict;
use Test::More;
use MyTest::New;

use strict;
plan tests => 8;

# Tests here

my $new = new MyTest::New;

is("${new}", "<New />", "Implicit construction ok");

MyTest::New->element_name('shiny');

$new = new MyTest::New;

is("${new}", "<shiny />", "Element name set ok");

$new = new MyTest::New ('spangly');

is("${new}", "<spangly />", "Element name override ok");

$new = new MyTest::New ('spangly', 'ns');

is($new->getPrefix, "ns", "Namespacing ok");

$new = new MyTest::New ({ foo => 1, bar => "Spaf" });

is($new->foo, 1, "Hashref attribute construct 1/2 ok");

is($new->bar, "Spaf", "Hashref attribute construct 2/2 ok");

$new = new MyTest::New ([ baz => 1, foo => "Spoing" ]);

is("${new}", qq!<shiny baz="1" foo="Spoing" />!,
      "Arrayref attribute construct ok");

$new = new MyTest::New ('spaf', { bar => 2 });

is("${new}", qq!<spaf bar="2" />!, "Mixed construct ok");
