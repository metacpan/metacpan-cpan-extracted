use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Backed_Objects',
    AUTHOR              => q{Victor Porton <porton@narod.ru>},
    VERSION_FROM        => 'lib/Backed_Objects.pm',
    ABSTRACT_FROM       => 'lib/Backed_Objects.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Backed_Objects-*' },
);
