use inc::Module::Install;

name	        'Catalyst-ActionRole-Tabs';
all_from        'lib/Catalyst/ActionRole/Tabs.pm';
author	        'Bernhard Graf <graf@cpan.org>';
license	        'perl';
repository      'http://github.com/augensalat/Catalyst-ActionRole-Tabs/tree/master';

build_requires  'Test::More';
build_requires  'URI';

requires        'Catalyst::Runtime';
requires        'Catalyst::Controller::ActionRole';
requires        'Moose';
requires        'namespace::autoclean';

WriteAll;

