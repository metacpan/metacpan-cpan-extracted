use strict;
use warnings;
use inc::Module::Install;

name 'Catalyst-Controller-AllowDisable';
author 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>';
repository 'http://svn.coderepos.org/share/lang/perl/Catalyst-Controller-AllowDisable/trunk';

all_from 'lib/Catalyst/Controller/AllowDisable.pm';
requires 'Test::More'        => 0;
requires 'Catalyst::Runtime' => 5.70;
requires 'MRO::Compat'       => 0;
license 'perl';
auto_install;
WriteAll;

