use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Archive::Tar::Stream',
    AUTHOR              => q{Bron Gondwana <perlcode@brong.net>},
    VERSION_FROM        => 'lib/Archive/Tar/Stream.pm',
    ABSTRACT_FROM       => 'lib/Archive/Tar/Stream.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Archive-Tar-Stream-*' },
);
