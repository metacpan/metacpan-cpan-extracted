use strict;
use warnings;
use inc::Module::Install;

name 'Acme-PSON';
author 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>';
all_from 'lib/Acme/PSON.pm';
requires 'Test::More'     => 0;
requires 'Readonly'       => 0;
requires 'Exporter::Lite' => 0;
license 'perl';
auto_install;
WriteAll;
