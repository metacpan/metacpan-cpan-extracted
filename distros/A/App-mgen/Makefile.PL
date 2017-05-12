use inc::Module::Install;

name 'App-mgen';
all_from 'lib/App/mgen.pm';

requires 'Time::Piece';

tests 't/*.t';

test_requires 'Test::More';

auto_set_repository;
auto_include;
install_script('bin/mgen');

WriteAll;
