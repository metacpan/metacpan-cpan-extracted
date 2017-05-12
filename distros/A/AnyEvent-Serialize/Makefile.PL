use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::Serialize',
    VERSION_FROM      => 'lib/AnyEvent/Serialize.pm', # finds $VERSION
    PREREQ_PM         => {
    	
        'Data::StreamSerializer'        => '0.05',
        'Data::StreamDeserializer'      => '0.04',
        'AnyEvent'                      => 0,
        'AnyEvent::AggressiveIdle'      => '0.01',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AnyEvent/Serialize.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
