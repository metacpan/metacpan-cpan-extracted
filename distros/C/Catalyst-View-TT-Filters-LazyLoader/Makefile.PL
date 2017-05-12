use strict;
use warnings;
use inc::Module::Install;

name 'Catalyst-View-TT-Filters-LazyLoader';
author 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>';
all_from 'lib/Catalyst/View/TT/Filters/LazyLoader.pm';
requires 'Test::More'            => 0;
requires  'Template::Filters::LazyLoader' => 0.05;
requires  'Catalyst'                      => 5.7;
requires 'Catalyst::View::TT'            => 0;
requires 'Catalyst::Action::RenderView'  => 0;
license 'perl';
auto_install;
WriteAll;

