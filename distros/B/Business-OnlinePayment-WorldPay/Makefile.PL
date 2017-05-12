use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::OnlinePayment::WorldPay',
    VERSION_FROM      => 'lib/Business/OnlinePayment/WorldPay.pm', # finds $VERSION
    PREREQ_PM         => {     # e.g., Module::Name => 1.1
        Business::OnlinePayment => 0,
        Net::SSLeay             => 0,
        MIME::Base64            => 0,
        XML::TreeBuilder        => 0,
        Template                => 0,
        Test::Exception         => 0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/OnlinePayment/WorldPay.pm', # retrieve abstract from module
       AUTHOR         => 'XXX <XXX@XXX') : ()),
);
