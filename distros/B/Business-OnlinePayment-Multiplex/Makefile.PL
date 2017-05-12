use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::OnlinePayment::Multiplex',
    VERSION_FROM      => 'lib/Business/OnlinePayment/Multiplex.pm', # finds $VERSION
    PREREQ_PM         => {'Test::More'  =>  '',
                          'Business::OnlinePayment' => '',
                          'Business::OnlinePayment::StoredTransaction' => ''}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/OnlinePayment/Multiplex.pm', # retrieve abstract from module
       AUTHOR         => 'mock <mock@obscurity.org>') : ()),
);
