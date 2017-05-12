use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.1.1.1 2006/08/27 04:33:05 plobbes Exp $
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Business::OnlinePayment::PayPal',
    VERSION_FROM => 'lib/Business/OnlinePayment/PayPal.pm',
    PREREQ_PM    => {
        Business::OnlinePayment => 0,
        Business::PayPal::API   => 0,
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/Business/OnlinePayment/PayPal.pm'
            ,    # retrieve abstract from module
            AUTHOR => 'Phil Lobbes <phil@perkpartners.com>'
          )
        : ()
    ),
);
