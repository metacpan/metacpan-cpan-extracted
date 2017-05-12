use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bot::BasicBot::Pluggable::Module::StripFormatting',
    AUTHOR           => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM     => 'lib/Bot/BasicBot/Pluggable/Module/StripFormatting.pm',
    ABSTRACT_FROM    => 'lib/Bot/BasicBot/Pluggable/Module/StripFormatting.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
        'Bot::BasicBot::Pluggable::Module' => 0,
        'IRC::Utils' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bot-BasicBot-Pluggable-Module-StripFormatting-*' },
);
