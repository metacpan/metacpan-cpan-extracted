use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bot::BasicBot::Pluggable::Module::Abuse::YourMomma',
    AUTHOR              => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM        => 'lib/Bot/BasicBot/Pluggable/Module/Abuse/YourMomma.pm',
    ABSTRACT_FROM       => 'lib/Bot/BasicBot/Pluggable/Module/Abuse/YourMomma.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bot-BasicBot-Pluggable-Module-Abuse-YourMomma-*' },
);
