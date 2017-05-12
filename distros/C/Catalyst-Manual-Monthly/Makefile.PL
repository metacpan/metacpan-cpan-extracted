use inc::Module::Install;

name     'Catalyst-Manual-Monthly';
all_from 'lib/Catalyst/Manual/Monthly.pm';
author   q{Kieren Diment <zarquon@cpan.org>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

