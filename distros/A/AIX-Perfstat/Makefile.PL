use lib qw(inc);
use Devel::AssertOS qw(AIX);
use Devel::CheckLib;

# Prompt the user here for any paths and other configuration

check_lib_or_exit(
    # fill in what you prompted the user for here
    lib => [qw(perfstat)]
);




use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AIX::Perfstat',
    VERSION_FROM      => 'lib/AIX/Perfstat.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AIX/Perfstat.pm', # retrieve abstract from module
       AUTHOR         => 'Richard Holden <aciddeath@cpan.org>') : ()),
    LIBS              => ['-lperfstat'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -Icpu/ -Inetinterface/ -Idisk/ -Imemory/', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES) cpu/cpu.o disk/disk.o netinterface/netinterface.o memory/memory.o', # link all the C files too
);
