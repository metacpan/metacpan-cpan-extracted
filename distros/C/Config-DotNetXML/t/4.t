use strict;
use Test::More tests => 2;

use_ok('Config::DotNetXML', File => 't/1.t.config',Package => 'Quux');


no warnings 'once';

ok($Quux::appSettings{Foo} eq 'Bar', 'Import into different package');
