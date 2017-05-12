use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::OnlinePayment::Capstone',
    VERSION_FROM      => 'lib/Business/OnlinePayment/Capstone.pm', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
                           'Business::OnlinePayment' => 0,

                           # for HTTPS (maybe it should be a separate dist?)
                           'URI::Escape' => 0,
                           'Tie::IxHash' => 0,

                           # 'Net::SSLeay' => 0,
                           # or 'Crypt::SSLeay' => 0,
                           #    'URI
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/OnlinePayment/Capstone.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Kohler <ivan-capstone@420.am>') : ()),
);
