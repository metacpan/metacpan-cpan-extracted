use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bot::BasicBot::Pluggable::Module::CPANLinks',
    AUTHOR              => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM        => 'lib/Bot/BasicBot/Pluggable/Module/CPANLinks.pm',
    ABSTRACT_FROM       => 'lib/Bot/BasicBot/Pluggable/Module/CPANLinks.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Bot::BasicBot::Pluggable' => 0,
        'URI::Title' => 0,
        'Module::Load' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bot-BasicBot-Pluggable-Module-CPANLinks-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/bigpresh/Bot-BasicBot-Pluggable-Module-CPANLinks',
            bugtracker => 'https://github.com/bigpresh/Bot-BasicBot-Pluggable-Module-CPANLinks/issues',
            homepage   => 'https://github.com/bigpresh/Bot-BasicBot-Pluggable-Module-CPANLinks/',
        },  
    },
);
