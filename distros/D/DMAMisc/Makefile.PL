#
# Copyright (C) 2008 DMA.
#

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DMAMisc',
    'DISTNAME'  => 'DMAMisc',
    'ABSTRACT'  => 'Misc support classes for DMA projects',
    'AUTHOR'    => 'Dale Amon',
    'VERSION_FROM' => 'Version',
    'PREREQ_PM' => {'Exporter' => 0, 'POSIX' => 0, 'DBI' => 0, 'Fault::DebugPrinter' => 0, 'Fault::Errorhandler' => 0 },
    'dist'      => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
    'clean'     => {FILES => "*/*/*~ *~ .#* */*/.#*"},
);
