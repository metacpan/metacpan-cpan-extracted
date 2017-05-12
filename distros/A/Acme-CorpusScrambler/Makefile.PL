use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::CorpusScrambler',
    VERSION_FROM        => 'lib/Acme/CorpusScrambler.pm',
    ABSTRACT_FROM       => 'lib/Acme/CorpusScrambler.pm',
    AUTHOR              => 'shelling, <navyblueshellingford@gmail.com>',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Text::Greeking::zh_TW' => '0.0.4',
        'IO::All' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-CorpusScrambler-*' },
);
