use 5.008001;
# use ExtUtils::MakeMaker;
use lib '.';
use inc::Module::Install;	# was "use ExtUtils::MakeMaker;"]G]
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::Init',
    VERSION_FROM      => 'lib/Class/Init.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/Init.pm', # retrieve abstract from module
       AUTHOR         => 'Richard Soderberg <perl@crystalflame.net>') : ()),
);
check_nmake();			# make sure the user have nmake
par_base('RSOD');		# your CPAN ID or a URL
fetch_par() unless can_cc();	# use precompiled PAR only if necessary
