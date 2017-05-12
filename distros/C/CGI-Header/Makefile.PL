use inc::Module::Install;

all_from 'lib/CGI/Header.pm';
readme_from 'lib/CGI/Header.pm';

repository 'https://github.com/anazawa/p5-CGI-Header';

requires 'Carp' => '1.10';
requires 'CGI'  => '3.51';
requires 'parent';

test_requires 'Test::More' => '0.98';
test_requires 'Test::Pod'  => '1.45';
test_requires 'Test::MockTime';
test_requires 'Test::Exception';
test_requires 'Test::Output';
test_requires 'CGI::Simple';
test_requires 'base';

no_index directory => 'examples';

tests 't/*.t xt/*.t';

WriteAll;
