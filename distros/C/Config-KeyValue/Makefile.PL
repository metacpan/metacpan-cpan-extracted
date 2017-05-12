use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Config::KeyValue',
    AUTHOR              => 'blair christensen <blair.christensen@gmail.com>',
    VERSION_FROM        => 'lib/Config/KeyValue.pm',
    ABSTRACT_FROM       => 'lib/Config/KeyValue.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Config-KeyValue-*' },
);
