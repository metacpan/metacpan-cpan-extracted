use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::OnlinePayment::PaymenTech',
    AUTHOR              => 'Mark Wells <mark@freeside.biz>',
    VERSION_FROM        => 'lib/Business/OnlinePayment/PaymenTech.pm',
    ABSTRACT_FROM       => 'lib/Business/OnlinePayment/PaymenTech.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Business::OnlinePayment' => 3,
        'Business::OnlinePayment::HTTPS' => 0,
        'XML::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-OnlinePayment-PaymenTech-*' },
);
