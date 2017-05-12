use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Config::Simple::Extended',
    AUTHOR              => 'Hugh Esco <hesco@campaignfoundations.com>',
    VERSION_FROM        => 'lib/Config/Simple/Extended.pm',
    ABSTRACT_FROM       => 'lib/Config/Simple/Extended.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                 'Test' => 0,
              'FindBin' => 0,
            'Test::Pod' => 0,
           'Test::More' => 0,
           'Test::Deep' => 0,
         'Data::Dumper' => 0,
       'Config::Simple' => 0,
       'File::PathInfo' => 0,
  'Test::Pod::Coverage' => 0,
            'UNIVERSAL' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Config-Simple-Extended-*' },
);
