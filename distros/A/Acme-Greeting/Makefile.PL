use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Acme/Greeting.pm';

build_requires  'Test::More'        => '0.42';

requires self => 0;

WriteAll;


