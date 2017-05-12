use strict;
use warnings;
use Test::More tests => 2;

our (%appSettings);
use_ok('Config::DotNetXML',Section => 'FooSection');

ok($appSettings{Foo} eq 'Bar','Variable is there');
