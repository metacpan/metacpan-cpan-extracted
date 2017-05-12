use inc::Module::Install;
name 'App-LoadWatcher';
all_from 'lib/App/LoadWatcher.pm';

requires 'Pod::Usage';
requires 'Unix::Uptime';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

install_script 'bin/load_watcher';
auto_set_repository;
#auto_include;
WriteAll;
