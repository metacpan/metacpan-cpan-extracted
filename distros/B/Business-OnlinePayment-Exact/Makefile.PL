use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::OnlinePayment::Exact',
    VERSION_FROM      => 'lib/Business/OnlinePayment/Exact.pm', # finds $VERSION
    PREREQ_PM         => {'Test::More'  =>  0,
                          'Term::ReadLine' => 0,
                          'Term::ReadLine::Gnu' => 0,
                          'Business::OnlinePayment' => '2.01',
                          'SOAP::Lite' => '0.65_3'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/OnlinePayment/Exact.pm', # retrieve abstract from module
       AUTHOR         => 'mock <mock@obscurity.org>') : ()),
);
