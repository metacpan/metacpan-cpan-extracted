use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Archive::StringToZip',
    AUTHOR              => 'Robbie Bow <robbiebow@canada.com>',
    VERSION_FROM        => 'lib/Archive/StringToZip.pm',
    ABSTRACT_FROM       => 'lib/Archive/StringToZip.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Archive::Zip'      => 0,
        'IO::String'        => 0,
        'Test::Exception'   => 0,
        'Test::More'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Archive-StringToZip-*' },
);
