use inc::Module::Install;

name 'DBD-Simulated';
all_from 'lib/DBD/Simulated.pm';
author 'eGENTIC Systems Sebastian Willing <sewi@cpan.org>';
license 'perl';

build_requires 'Test::More';

recommends 'DBI' => 0;

test_requires 'Test::More'  => 0;

auto_install;

WriteAll;
