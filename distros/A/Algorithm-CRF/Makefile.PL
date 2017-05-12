use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::CRF',
    VERSION_FROM      => 'lib/Algorithm/CRF.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Algorithm/CRF.pm', # retrieve abstract from module
       AUTHOR         => 'Cheng-Lung Sung <clsung@FreeBSD.org>') : ()),
    CC		      => 'c++',
    LIBS              => ['-lcrfpp'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -Wall -Wno-deprecated', # e.g., '-I. -I/usr/include/other'
    XSOPT             => '-C++',
    LD                => '$(CC)',
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
