use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ACL::Lite',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/ACL/Lite.pm',
    ABSTRACT_FROM       => 'lib/ACL/Lite.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ACL-Lite-*' },
);
