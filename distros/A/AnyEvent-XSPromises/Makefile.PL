use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::XSPromises',
    VERSION_FROM      => 'lib/AnyEvent/XSPromises/Loader.pm', # finds $VERSION
    PREREQ_PM         => {
        AnyEvent => "7",
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AnyEvent/XSPromises.pm', # retrieve abstract from module
       AUTHOR         => 'Tom van der Woerdt <tomvanderwoerdt@sd.apple.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    LICENSE           => "perl_5",
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
