use strict;
use warnings;
use inc::Module::Install;

name 'Catalyst-Plugin-Log-Colorful';
author 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>';
repository 'http://svn.coderepos.org/share/lang/perl/Catalyst-Plugin-Log-Colorful/trunk';

all_from 'lib/Catalyst/Plugin/Log/Colorful.pm';
requires 'Test::More'        => 0;
requires 'Catalyst::Runtime' => 5.70;
requires 'Catalyst::Log'     => 0;
requires 'MRO::Compat'       => 0;
requires 'Term::ANSIColor'   => 0;
requires 'Data::Dumper'      => 0;
license 'perl';
auto_install;
WriteAll;
