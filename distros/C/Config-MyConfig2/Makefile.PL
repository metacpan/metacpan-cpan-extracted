use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Config::MyConfig2',
    AUTHOR              => q{Markus Guertler <markus@guertler.org>},
    VERSION_FROM        => 'lib/Config/MyConfig2.pm',
    ABSTRACT_FROM       => 'lib/Config/MyConfig2.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES		=> [ qw(bin/myconfig-demo.pl bin/myconfig-demo.cfg) ],
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Config-MyConfig2-*' },
);
