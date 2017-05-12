use inc::Module::Install;
name 'App-Lazyd';
all_from 'lib/App/Lazyd.pm';

requires
    'Net::Delicious' => '1.13',
    'URI::Title' => '1.82',
    'YAML::Tiny' => '1.36';

install_script 'bin/lazyd';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';

auto_include;
WriteAll;
