use strict;
use warnings;
use Test::More tests => 2;

our (%appSettings);
use_ok('Config::DotNetXML', File => 't/1.t.config');

ok($appSettings{Foo} eq 'Bar', 'Recognises the File import');
