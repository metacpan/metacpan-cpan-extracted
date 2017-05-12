use inc::Module::Install;

all_from 'lib/CGI/Header/PSGI.pm';
readme_from 'lib/CGI/Header/PSGI.pm';

repository 'https://github.com/anazawa/p5-CGI-Header-PSGI';

requires 'Carp' => '1.10';
requires 'CGI::Header' => '0.62';
requires 'parent';

test_requires 'Test::More' => '0.98';
test_requires 'Test::Pod'  => '1.45';
test_requires 'Test::MockTime';
test_requires 'CGI::PSGI'  => '0.15';

tests 't/*.t xt/*.t';

WriteAll;
