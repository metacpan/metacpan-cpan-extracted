use 5.14.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @exec_files = qw(bin/bgpmon_filter);

WriteMakefile(
    NAME              => 'BGPmon',
    VERSION_FROM      => 'VERSION',
    EXE_FILES         => ['bin/bgpmon_filter'],
    PREREQ_PM         => {'Test'        =>  0,
                          'BGPmon::Log' => 2.02,
                          'BGPmon::Configure' => 2.02,
                          'BGPmon::Fetch' => 2.02,
                          'BGPmon::Validate' => 1.0,
                	  'Thread::Queue' => 0,
                  	  'Net::IP' => 0,
                  	  'Regexp::IPv6' => 0,
            	          'Net::Address::IP::Local' => 0,
                  	  'Time::HiRes' => 0,
                  	  'BGPmon::CPM::PList::Manager' => 0,
}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'bin/bgpmon_filter', # retrieve abstract from module
       AUTHOR         => 'M. Lawrence Weikum <mweikum@rams.colostate.edu>' ) : ()),
);
