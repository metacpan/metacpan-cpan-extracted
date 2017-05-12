use 5.14.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @exec_files = qw();

WriteMakefile(
    NAME              => 'BGPmon',
    VERSION_FROM      => 'VERSION', # finds $VERSION
    EXE_FILES         => [],
    PREREQ_PM         => {'Test'        =>  0,
                          'Sys::Syslog' => 0,
                          'Getopt::Long' => 0,
                          'List::MoreUtils' => 0,
                          'POSIX' => 0,
                          'Sys::Hostname' => 0,
                          'File::Path' => 0,
                          'IO::Socket' => 0,
                          'IO::Select' => 0,
                          'LWP::Simple' => 6.00,
                          'XML::LibXML' => 1.89,
                          'XML::LibXML::Simple' => 0.92,
                          'Net::IP' => 1.25,
                          'IO::Uncompress::AnyUncompress' => 0,
}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/BGPmon/Log.pm', # retrieve abstract from module
       AUTHOR         => 'Catherine Olschanowsky <cathie@cs.colostate.edu>, M. Lawrence Weikum <weikum@cs.colostate.edu>, Kaustubh Gadkari <kaustubh@cs.colostate.edu' ) : ()),
);
