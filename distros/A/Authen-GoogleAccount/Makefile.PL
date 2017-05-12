use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Authen::GoogleAccount',
    AUTHOR              => 'Hogeist <mahito@cpan.org>',
    VERSION_FROM        => 'lib/Authen/GoogleAccount.pm',
    ABSTRACT_FROM       => 'lib/Authen/GoogleAccount.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Authen-GoogleAccount-*' },
);
