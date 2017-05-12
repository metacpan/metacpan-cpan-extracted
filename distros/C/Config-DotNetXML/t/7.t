package MyTest;

use strict;
use warnings;
use Test::More tests => 2;

use_ok('Config::DotNetXML', File => 't/1.t.config');

no warnings 'once';

ok($MyTest::appSettings{Foo} eq 'Bar', 'Imports to correct package');
