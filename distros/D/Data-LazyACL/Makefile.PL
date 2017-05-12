use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Data::LazyACL',
    AUTHOR       => 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>',
    VERSION_FROM => 'lib/Data/LazyACL.pm',
    ABSTRACT_FROM=> 'lib/Data/LazyACL.pm',
    PL_FILES     => {},
    PREREQ_PM    => {
        'Math::BigInt'    => 0,
        'Test::Exception' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-LazyACL-*' },
);
