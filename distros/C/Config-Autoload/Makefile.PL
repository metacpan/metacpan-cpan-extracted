use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Config::Autoload',
    AUTHOR              => q{Jeff Pang <pangj@arcor.de>},
    VERSION_FROM        => 'lib/Config/Autoload.pm',
    ABSTRACT_FROM       => 'lib/Config/Autoload.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Config-Autoload-*' },
);
