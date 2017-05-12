use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Binutils::Objdump',
    VERSION_FROM      => 'lib/Binutils/Objdump.pm', # finds $VERSION
    PREREQ_PM         => {},
    EXE_FILES => [ 'odasm' ],
);



