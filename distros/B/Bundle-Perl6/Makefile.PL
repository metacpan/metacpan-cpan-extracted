use inc::Module::Install;
include 'Module::AutoInstall';

name 'Bundle-Perl6';
all_from 'lib/Bundle/Perl6.pm';
perl_version '5.006';

test_requires 'Test::More' => '0.70';
extra_tests;

auto_install;
auto_include;
WriteAll;
