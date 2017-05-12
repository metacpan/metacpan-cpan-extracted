use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::OnlinePayment::Jety',
    AUTHOR              => 'Mark Wells <mark@freeside.biz>',
    VERSION_FROM        => 'lib/Business/OnlinePayment/Jety.pm',
    ABSTRACT_FROM       => 'lib/Business/OnlinePayment/Jety.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Tie::IxHash' => 0,
        'Date::Format' => 0,
        'Business::OnlinePayment' => 0,
        'Net::HTTPS::Any' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-OnlinePayment-Jety-*' },
);
