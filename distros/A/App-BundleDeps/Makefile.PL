use inc::Module::Install;

name 'App-BundleDeps';
all_from 'lib/App/BundleDeps.pm';

requires 'local::lib';
requires 'YAML';
# versions below 0.9910 will fail to install zipped archives.
requires 'App::cpanminus' => '0.9910';

install_script 'script/bundledeps';
recommends 'YAML::XS';
test_requires 'Test::More';

tests 't/*.t';
author_tests 'xt';

WriteAll;
