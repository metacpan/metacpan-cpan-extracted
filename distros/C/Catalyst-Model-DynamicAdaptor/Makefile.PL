use strict;
use warnings;
use inc::Module::Install;

name 'Catalyst-Model-DynamicAdaptor';
author 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>';
all_from 'lib/Catalyst/Model/DynamicAdaptor.pm';
requires 'Catalyst'                   => 0;
requires 'Catalyst::Model'            => 0;
requires 'Test::More'                 => 0;
requires 'Test::Spelling'             => 0;
requires 'Module::Recursive::Require' => 0;
recommends 'Test::Pod::Coverage'      => 0;
recommends 'Test::Pod'                => 0;

license 'perl';
auto_install;
WriteAll;
