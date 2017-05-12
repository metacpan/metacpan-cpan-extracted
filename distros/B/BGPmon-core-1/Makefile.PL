use 5.14.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @exec_files = qw(bin/bgpmon-filter);

WriteMakefile(
    NAME              => 'BGPmon',
    VERSION_FROM      => 'VERSION', # finds $VERSION
    EXE_FILES         => ['bin/bgpmon_filter'],
    PREREQ_PM         => {'Test'        =>  0,
                          'Sys::Syslog' => 0,
			  'Thread::Queue' => 0,
                          'XML::LibXML' => 0,
                          'WWW::Curl::Easy' => 0,
                          'XML::LibXML::Simple' => 0,
			  'Net::IP' => 0,
  			  'Regexp::IPv6' => 0,
            	          'Net::Address::IP::Local' => 0,
			  'Time::HiRes' => 0,
			  'BGPmon::CPM::PList::Manager' => 0,
}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/BGPmon/Log.pm', # retrieve abstract from module
       AUTHOR         => 'Catherine Olschanowsky <cathie@cs.colostate.edu>, M. Lawrence Weikum <weikum@cs.colostate.edu>, Kaustubh Gadkari <kaustubh@cs.colostate.edu' ) : ()),
);
