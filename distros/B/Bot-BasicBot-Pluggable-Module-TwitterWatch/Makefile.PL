use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bot::BasicBot::Pluggable::Module::TwitterWatch',
    AUTHOR              => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM        => 'lib/Bot/BasicBot/Pluggable/Module/TwitterWatch.pm',
    ABSTRACT_FROM       => 'lib/Bot/BasicBot/Pluggable/Module/TwitterWatch.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'Bot::BasicBot::Pluggable::Module' => 0,
        'HTML::Entities'     => 0,
        'Net::Twitter::Lite' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bot-BasicBot-Pluggable-Module-TwitterWatch-*' },
);
