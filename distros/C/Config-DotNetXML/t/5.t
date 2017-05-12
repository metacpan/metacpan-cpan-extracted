use strict;
use Test::More tests => 2;

use_ok('Config::DotNetXML', File => 't/1.t.config',VarName => 'Quux');


our %Quux;
ok($Quux{Foo} eq 'Bar', 'Import into different variable');
