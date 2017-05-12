use strict;
use warnings;
use inc::Module::Install;

name 'Catalyst-Model-CacheFunky-Loader';
author 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>';
all_from 'lib/Catalyst/Model/CacheFunky/Loader.pm';
requires 'Test::More'                     => 0;
requires 'Catalyst'                       => 0;
requires 'Cache::Funky'                   => 0;
requires 'Catalyst::Plugin::ConfigLoader' => 0;
requires 'Module::Recursive::Require'     => 0.04;
requires 'Test::Spelling'                 => 0;

license 'perl';
auto_install;
WriteAll;
