use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    MIN_PERL_VERSION => '5.6.2',
    NAME             => 'DBIx::JSON',
    AUTHOR           => 'Koji Komatsu <yosty@cpan.org>',
    LICENSE          => 'perl_5',
    VERSION_FROM     => 'lib/DBIx/JSON.pm',
    ABSTRACT_FROM    => 'lib/DBIx/JSON.pm',
    PL_FILES         => {},
    PREREQ_PM        => {
        'Test::More' => 0,
        'DBI'        => '1.15',
        'JSON::Syck' => 0,
        'Carp'       => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'DBIx-JSON-*' },
);
