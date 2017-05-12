use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bit::Util',
    VERSION_FROM      => 'lib/Bit/Util.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
              # OPTIMIZE => '-g -O0',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bit/Util.pm', # retrieve abstract from module
       AUTHOR         => 'Salvador Fandino <salva@>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
