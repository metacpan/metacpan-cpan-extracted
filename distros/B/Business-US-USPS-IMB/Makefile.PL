use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::US::USPS::IMB',
    VERSION_FROM      => 'IMB.pm', # finds $VERSION
    PREREQ_PM         => {
	    'Test::More'	=> 0,
	    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'IMB.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Nighswonger') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    MYEXTLIB          => 'libs/libusps4cb$(LIB_EXT)',
	# Un-comment this if you add C files to link with later:
     #OBJECT            => '$(O_FILES)', # link all the C files too
);

sub MY::postamble {
'
$(MYEXTLIB): libs/Makefile
	cd libs && $(MAKE) $(PASSTHRU)
';
}
