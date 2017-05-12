use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::OnlinePayment::TransactionCentral',
    VERSION_FROM      => 'lib/Business/OnlinePayment/TransactionCentral.pm', # finds $VERSION
    PREREQ_PM         => {
                           'Business::OnlinePayment' => 3,

                           # for HTTPS (maybe it should be a separate dist?)
                           'URI::Escape' => 0,
                           'Tie::IxHash' => 0,

                           # 'Net::SSLeay' => 0,
                           # or 'Crypt::SSLeay' => 0,
                           #    'URI
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/OnlinePayment/TransactionCentral.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Kohler <ivan-transactioncentral@420.am>') : ()),
);
