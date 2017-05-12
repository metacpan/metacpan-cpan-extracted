use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bundle::CIPRES',
    AUTHOR              => 'Rutger A. Vos, rvosa@sfu.ca',
    VERSION_FROM        => 'lib/Bundle/CIPRES.pm',
    ABSTRACT_FROM       => 'lib/Bundle/CIPRES.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bundle-CIPRES-*' },
);