use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Plugin::ENV',
    VERSION_FROM      => 'lib/Catalyst/Plugin/ENV.pm', # finds $VERSION
    PREREQ_PM         => {
        'Catalyst' => 0,
        'Test::Strict' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Plugin/ENV.pm', # retrieve abstract from module
       AUTHOR         => 'PLCGI <plcgi1@gmail.com>') : ()),
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
