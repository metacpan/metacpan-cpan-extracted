use inc::Module::Install;

name     'Config-Versioned';
all_from 'lib/Config/Versioned.pm';
#author   'Scott T. Hardin <mrscotty@hnsc.de>';
#license  'perl';

requires 'Moose';
requires 'Git::PurePerl';
requires 'Config::Std';
recommends 'Config::Any';
recommends 'YAML::XS';
recommends 'Config::Merge';

build_requires 'Test::More';
build_requires 'DateTime';
build_requires 'Path::Class';

auto_install;

install_script  'bin/cfgver';


WriteAll;

