use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::UNLreport',
    VERSION_FROM      => 'lib/Data/UNLreport.pm', # finds $VERSION
    EXE_FILES         => [ 'scripts/beautify-unl.pl' ],
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Formats column-oriented data into uniform column sizes',
       AUTHOR         => 'Jacob Salomon <jakesalomon@yahoo.com>') : ()),
);

# Author's Note: Regarding the line with "ABSTRACT =>"
# This was originally:
# (ABSTRACT_FROM  => 'lib/Data/UNLreport.pm', # retrieve abstract from module
# as generated y h2xs. However, I was getting the following unpleasantness:
#
#WARNING: Setting ABSTRACT via file 'lib/Data/UNLreport.pm' failed
# at /usr/lib/perl5/5.10/ExtUtils/MakeMaker.pm line 583
#
# A search of Google for the above phrase shows me that "
# 1. I am not alone
# 2. In all such instances that I purused, the user took the same step I
#    took, rather than break his head trying to get it to correctly pull
#    the ABSTRACT out of the pod listing.
#
# I will not be the first one to solve this. :-(
