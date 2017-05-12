use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::OnlinePayment::FirstDataGlobalGateway',
    AUTHOR              => q{Ivan Kohler <ivan-firstdataglobalgateway@420.am>},
    VERSION_FROM        => 'lib/Business/OnlinePayment/FirstDataGlobalGateway.pm',
    ABSTRACT_FROM       => 'lib/Business/OnlinePayment/FirstDataGlobalGateway.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Business::OnlinePayment' => 3.01,
        'SOAP::Lite' => 0,
        'Data::Dumper' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-OnlinePayment-FirstDataGlobalGateway-*' },
);

