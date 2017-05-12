use strict;
use warnings;
use inc::Module::Install;

name 'Config-Multi';
author 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>';
all_from 'lib/Config/Multi.pm';
requires 'Test::Base'            => 0;
requires 'DirHandle'             => 0;
requires 'Config::Any'           => 0;
requires 'Class::Accessor'       => 0;
requires 'Unicode::RecursiveDowngrade' => 0;
requires 'Encode'                => 0;
recommends 'YAML'                => 0; # for testing
recommends 'YAML::Syck'          => 0; # for testing
recommends 'Test::Pod::Coverage' => 0;
recommends 'Test::Pod'           => 0;
recommends 'Test::Spelling'      => 0;

license 'perl';
auto_install;
WriteAll;
