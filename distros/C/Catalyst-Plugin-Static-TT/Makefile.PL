use strict;
use warnings;
use inc::Module::Install;

name 'Catalyst-Plugin-Static-TT';
author 'Hans Dieter Pearcey <hdp@cpan.org>';
all_from;

build_requires 'Test::More'                => 0;
build_requires 'Test::MockObject::Extends' => 0;

requires 'Catalyst'         => '5.64';
requires 'File::Find::Rule' => 0;
requires 'File::Spec'       => 0;
requires 'NEXT'             => 0;
requires 'Template'         => 0;

WriteAll;
