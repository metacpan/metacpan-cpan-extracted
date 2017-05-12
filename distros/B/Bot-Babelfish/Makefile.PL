use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'Bot::Babelfish',
    LICENSE             => 'perl',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Bot/Babelfish.pm',
    ABSTRACT_FROM       => 'lib/Bot/Babelfish.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Bot::BasicBot' => '0.5',
        'Carp' => '0',
        'Encode' => '0',
        'I18N::LangTags' => '0',
        'Lingua::Translate' => '0',
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bot-Babelfish-*' },
);
