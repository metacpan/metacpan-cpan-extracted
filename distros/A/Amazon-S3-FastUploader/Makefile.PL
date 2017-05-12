use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Amazon::S3::FastUploader',
    AUTHOR              => q{DQNEO <dqneoo@gmail.com>},
    VERSION_FROM        => 'lib/Amazon/S3/FastUploader.pm',
    ABSTRACT_FROM       => 'lib/Amazon/S3/FastUploader.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Amazon::S3' => 0,
        'Parallel::ForkManager' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Amazon-S3-FastUploader-*' },
);
