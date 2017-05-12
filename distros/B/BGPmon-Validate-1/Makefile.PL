use 5.14.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

#my @exec_files = qw();

WriteMakefile(
    NAME              => 'BGPmon',
    VERSION_FROM      => 'VERSION', # finds $VERSION
#    EXE_FILES         => [''],
    PREREQ_PM         => {'Test'        => 0,
                          'XML::LibXML' => 0,
                          'BGPmon::Fetch' => 2.0,
}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'M. Lawrence Weikum <mweikum@rams.colostate.edu>' ) : ()),
);
