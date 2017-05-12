use strict;
use warnings;
use inc::Module::Install;

name 'Catalyst-Plugin-Config-Multi';
author 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>';
all_from 'lib/Catalyst/Plugin/Config/Multi.pm';
requires 'Test::More'            => 0;
requires 'Test::Spelling'        => 0;
requires 'Catalyst::Runtime'     => 5.70;
requires 'Config::Multi'         => 0.04;
recommends 'Test::Pod::Coverage' => 0;
recommends 'Test::Pod'           => 0;

license 'perl';
auto_install;
WriteAll;
