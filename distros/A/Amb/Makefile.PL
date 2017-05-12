# $Id: Makefile.PL,v 1.4 2008/09/03 12:56:14 dk Exp $
use ExtUtils::MakeMaker;
require 5.008_000;
WriteMakefile(
    'NAME'		=> 'Amb',
    'VERSION_FROM'	=> 'Amb.pm',
    'PREREQ_PM'		=> {PadWalker => 0, 'B::Generate' => '1.13'}, 
);
