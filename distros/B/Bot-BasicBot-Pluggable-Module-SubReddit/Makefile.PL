use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bot::BasicBot::Pluggable::Module::SubReddit',
    AUTHOR           => q{James Green <jkg@cpan.org>},
    VERSION_FROM     => 'lib/Bot/BasicBot/Pluggable/Module/SubReddit.pm',
    ABSTRACT_FROM    => 'lib/Bot/BasicBot/Pluggable/Module/SubReddit.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Bot::BasicBot::Pluggable' => 0,
    },
    PREREQ_PM => {
        'URI::Title' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bot-BasicBot-Pluggable-Module-SubReddit-*' },
);
