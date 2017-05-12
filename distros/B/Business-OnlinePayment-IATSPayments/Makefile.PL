use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::OnlinePayment::IATSPayments',
    AUTHOR              => q{Ivan Kohler <ivan-iatspayments@420.am>},
    VERSION_FROM        => 'lib/Business/OnlinePayment/IATSPayments.pm',
    ABSTRACT_FROM       => 'lib/Business/OnlinePayment/IATSPayments.pm',
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
    clean               => { FILES => 'Business-OnlinePayment-IATSPayments-*' },
);

