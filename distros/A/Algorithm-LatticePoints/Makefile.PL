#
# $Id: Makefile.PL,v 0.1 2007/02/04 05:45:16 dankogai Exp dankogai $
#
use strict;
use warnings;
use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::LatticePoints',
    VERSION_FROM      => 'lib/Algorithm/LatticePoints.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Algorithm/LatticePoints.pm', # retrieve abstract from module
       AUTHOR         => 'Dan Kogai <dankogai@dan.co.jp>') : ()),
);
