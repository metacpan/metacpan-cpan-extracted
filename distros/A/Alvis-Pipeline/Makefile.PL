# $Id: Makefile.PL,v 1.11 2006/08/31 16:12:02 mike Exp $

use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Alvis::Pipeline',
    VERSION_FROM      => 'lib/Alvis/Pipeline.pm', # finds $VERSION
    PREREQ_PM         => {
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Alvis/Pipeline.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Taylor <mike@indexdata.com>') : ()),
    EXE_FILES    => [ 'bin/alvis-pipeline-put.pl',
		      'bin/alvis-pipeline-put-documents.pl',
		      'bin/alvis-pipeline-filter.pl',
		      'bin/alvis-pipeline-get.pl',
		      'bin/alvis-zsink.pl' ],
);
