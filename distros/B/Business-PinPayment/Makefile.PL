use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::PinPayment',
    AUTHOR              => q{Xufeng (Danny) Liang <danny.glue@gmail.com>},
    VERSION_FROM        => 'lib/Business/PinPayment.pm',
    ABSTRACT_FROM       => 'lib/Business/PinPayment.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTTP::Request' => 0,
        'LWP::UserAgent' => 0,
        'Net::SSL' => 0,
        'JSON' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-PinPayment-*' },
);
