use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Config::apiLayers',
    AUTHOR              => 'Russell E Glaue',
    VERSION_FROM        => 'lib/Config/apiLayers.pm',
    ABSTRACT_FROM       => 'lib/Config/apiLayers.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM           => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Config-apiLayers-*' }
);
