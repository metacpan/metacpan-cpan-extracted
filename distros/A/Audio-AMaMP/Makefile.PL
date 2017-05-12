use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Audio::AMaMP',
    VERSION_FROM      => 'lib/Audio/AMaMP.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Audio/AMaMP.pm', # retrieve abstract from module
       AUTHOR         => 'Jonathan Worthington <jonathan@jwcs.net>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    MYEXTLIB          => 'amamp_binding/libamamp_binding$(LIB_EXT)',
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

sub MY::postamble {
'
$(MYEXTLIB): amamp_binding/Makefile
	cd amamp_binding && $(MAKE) $(PASSTHRU)
';
}