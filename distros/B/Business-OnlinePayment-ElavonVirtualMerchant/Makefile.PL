use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::OnlinePayment::ElavonVirtualMerchant',
    VERSION_FROM      => 'ElavonVirtualMerchant.pm', # finds $VERSION
    PREREQ_PM         => {Business::OnlinePayment::viaKLIX},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'ElavonVirtualMerchant.pm', # retrieve abstract from module
       AUTHOR         => 'Richard Siddall <elavon@elirion.net>') : ()),
);
