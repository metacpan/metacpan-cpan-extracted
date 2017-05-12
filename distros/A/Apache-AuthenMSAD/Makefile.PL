use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Apache::AuthenMSAD',
    AUTHOR              => 'Andrew McGregor <andy@txm.mobi>',
    VERSION_FROM        => 'lib/Apache/AuthenMSAD.pm',
    ABSTRACT_FROM       => 'lib/Apache/AuthenMSAD.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache-AuthenMSAD-*' },
);
