use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::FeatureFactory',
    AUTHOR              => 'Oldřich Krůza <Oldrich.Kruza@sixtease.net>',
    VERSION_FROM        => 'lib/Data/FeatureFactory.pm',
    ABSTRACT_FROM       => 'lib/Data/FeatureFactory.pm',
#    PM => {
#        'lib/Data/FeatureFactory.pm' => '$(INST_LIBDIR)/FeatureFactory.pm',
#    },
    PREREQ_PM           => {
        'Carp'            => 0,
        'File::Basename'  => 0,
        'File::Temp'      => 0,
        'Scalar::Util'    => 0,
        'Test::More'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-FeatureFactory-*' },
);
