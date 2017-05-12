use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bot::BasicBot::Pluggable::Module::WoWPVP',
    AUTHOR              => 'Franck CUNY <franck@breizhdev.net>',
    VERSION_FROM        => 'lib/Bot/BasicBot/Pluggable/Module/WoWPVP.pm',
    ABSTRACT_FROM       => 'lib/Bot/BasicBot/Pluggable/Module/WoWPVP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Games::WoW::PVP' => 0,
	'Bot::BasicBot::Pluggable::Module' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bot-BasicBot-Pluggable-Module-WoWPVP-*' },
);
