use 5.14.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#

my @exec_files = qw(bin/bgpmon-archiver.pl bin/bgpmon-archiver-status.pl);

WriteMakefile(
    NAME              => 'bgpmon-archiver',
    VERSION_FROM      => 'bin/bgpmon-archiver.pl',
    PREREQ_PM         => {'Test'        =>  0,
			                    'BGPmon::Log' => 0,
			                    'BGPmon::Fetch' => 0,
		                      'BGPmon::Translator::XFB2BGPdump' => 0,
		                      'BGPmon::Translator::XFB2PerlHash::Simple' => 0,
			                    'Cwd' => 0,
			                    'File::Path' => 0,
			                    'POSIX' => 0,
			                    'Getopt::Long' => 0,
			                    'Net::SMTP' => 0,
			 }, # e.g., Module::Name => 1.1
    EXE_FILES		=> \@exec_files,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'bin/bgpmon-archiver.pl', # retrieve abstract from module
       AUTHOR         => 'Kaustubh Gadkari <kaustubh@cs.colostate.edu>, M. Lawrence Weikum <mweikum@rams.colostate.edu>') : ()),
);
