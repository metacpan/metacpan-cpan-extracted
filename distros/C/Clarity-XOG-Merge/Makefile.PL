use strict;
use warnings;

use inc::Module::Install;

name     'Clarity-XOG-Merge';
all_from 'lib/Clarity/XOG/Merge.pm';
author   'Steffen Schwigon <ss5@renormalist.net>';
license  'perl';

author_requires 'Module::Install::WriteAll';

requires 'Test::More'; # [sic, for selftest]
requires 'Test::Deep'; # [sic, for selftest]
requires 'File::Temp';
requires 'File::Find::Rule';
requires 'Data::Dumper';
requires 'XML::Twig';
requires 'Moose';
requires 'App::Cmd';

#author_requires 'Module::Install::PAR';
#author_requires 'PAR::Packer';
#author_requires 'PAR::Dist';
#par_base "SCHWIGON";

install_script 'xogtool';

auto_install;

repository 'git://github.com/lhm/Clarity-XOG-Merge.git';
bugtracker 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Clarity-XOG-Merge';

WriteAll;
