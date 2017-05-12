use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DNS::SerialNumber::Check',
    AUTHOR              => q{Ken Peng <shorttag@gmail.com>},
    VERSION_FROM        => 'lib/DNS/SerialNumber/Check.pm',
    ABSTRACT_FROM       => 'lib/DNS/SerialNumber/Check.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::DNS'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DNS-SerialNumber-Check-*' },
);
