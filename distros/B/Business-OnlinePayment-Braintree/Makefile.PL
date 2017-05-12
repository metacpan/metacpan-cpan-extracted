use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::OnlinePayment::Braintree',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Business/OnlinePayment/Braintree.pm',
    ABSTRACT_FROM       => 'lib/Business/OnlinePayment/Braintree.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Business::OnlinePayment' => 3.01,
	'Net::Braintree' => 0.027000,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-OnlinePayment-Braintree-*' },
    META_MERGE        => {
        resources => {
            repository  => 'https://github.com/interchange/Business-OnlinePayment-Braintree',
            bugtracker => 'https://github.com/interchange/Business-OnlinePayment-Braintree/issues'
        },
    },
);
