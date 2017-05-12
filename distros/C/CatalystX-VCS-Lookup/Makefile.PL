use inc::Module::Install;

name     'CatalystX-VCS-Lookup';
all_from 'lib/CatalystX/VCS/Lookup.pm';
author   q{Oleg A. Mamontov <lonerr@cpan.org>};
license  'perl';

requires 'File::Which';
requires 'Moose::Role';

test_requires 'Catalyst::Runtime';
test_requires 'File::Copy::Recursive';
test_requires 'File::Spec::Functions';
test_requires 'FindBin';
test_requires 'Test::More';

auto_install;

WriteAll;

