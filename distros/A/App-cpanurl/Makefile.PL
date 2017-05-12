use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::cpanurl',
    AUTHOR              => q{Yuki Kimoto <kimoto.yuki@gmail.com>},
    VERSION_FROM        => 'lib/App/cpanurl.pm',
    ABSTRACT_FROM       => 'lib/App/cpanurl.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-cpanurl-*' },
    EXE_FILES => ['script/cpanurl']
);
