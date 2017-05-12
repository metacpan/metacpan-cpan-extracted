#!/usr/bin/perl
use ExtUtils::MakeMaker;
WriteMakefile (
    'NAME' => 'Config::Natural', 
    'VERSION_FROM' => 'lib/Config/Natural.pm', 
    'PREREQ_PM' => {
        'Carp' => 0, 
        'File::Spec' => 0, 
        'FileHandle' => 0, 
    }, 
    'PL_FILES' => {}, 
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Config/Natural.pm', 
       AUTHOR => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>') : ()),
);
