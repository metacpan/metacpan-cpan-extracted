use 5.010001;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Business::OnlinePayment::IPayment',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/Business/OnlinePayment/IPayment.pm',
    ABSTRACT_FROM    => 'lib/Business/OnlinePayment/IPayment.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
                  'Moo' => 1,
                  'XML::Compile::SOAP' => 0,
                  URI => 1,
                  'Crypt::SSLeay' => 0,
                  'XML::Compile::WSDL11' => 0,
                  'Business::OnlinePayment' => 3,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Business-OnlinePayment-IPayment-*' },
);
