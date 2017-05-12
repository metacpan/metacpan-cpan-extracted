use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Bot::BasicBot::Pluggable::Module::Twitter',
    LICENSE       => 'perl',
    AUTHOR        => 'franck cuny <franck.cuny@gmail.com>',
    VERSION_FROM  => 'lib/Bot/BasicBot/Pluggable/Module/Twitter.pm',
    ABSTRACT_FROM => 'lib/Bot/BasicBot/Pluggable/Module/Twitter.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'                       => 0,
        'version'                          => 0,
        'Test::Perl::Critic'               => 0,
        'Net::Twitter'                     => 0,
        'Bot::BasicBot::Pluggable::Module' => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bot-BasicBot-Pluggable-Module-Twitter-*' },
);
