use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bot::BasicBot::Pluggable::Module::GitHub',
    AUTHOR              => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM        => 'lib/Bot/BasicBot/Pluggable/Module/GitHub.pm',
    ABSTRACT_FROM       => 'lib/Bot/BasicBot/Pluggable/Module/GitHub.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Bot::BasicBot::Pluggable::Module' => 0,
        'Net::GitHub::V2' => 0,
        'YAML'            => 0,
        'LWP::Simple'     => 0,
        'JSON'            => 0,
        'URI::Title'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bot-BasicBot-Pluggable-Module-GitHub-*' },
);
