use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'DBIx::Dictionary',
    AUTHOR        => 'Igor Sutton <izut@cpan.org>',
    VERSION_FROM  => 'lib/DBIx/Dictionary.pm',
    ABSTRACT_FROM => 'lib/DBIx/Dictionary.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'      => 0,
        'Config::General' => 2.37,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'DBIx-Dictionary-*' },
);
