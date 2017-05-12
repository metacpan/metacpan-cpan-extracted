use strict;
use inc::Module::Install;
name 'Config-Divide';
all_from 'lib/Config/Divide.pm';
repository 'https://github.com/hirafoo/Config-Divide.git';

license 'perl';

requires $_ for qw/
    Config::Any
    File::Spec
/;

test_requires $_ for qw/
    Config::General
    Config::Tiny
    Test::Exception
    Test::Synopsis
    XML::Simple
    XML::NamespaceSupport
    YAML
/;
test_requires 'Test::More' => 0.98;
test_requires 'YAML::Syck' => 0.70;

auto_install;

WriteAll;
