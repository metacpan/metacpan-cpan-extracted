use inc::Module::Install;

name     'App-Nopaste-Service-AnyPastebin';
all_from 'lib/App/Nopaste/Service/AnyPastebin.pm';
author   q{Jason M Mills <jmmills@cpan.org>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

