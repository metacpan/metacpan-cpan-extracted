use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bot::BasicBot::Pluggable::Module::XKCD',
    AUTHOR              => q{Josh Holland <jrh@joshh.co.uk>},
    VERSION_FROM        => 'lib/Bot/BasicBot/Pluggable/Module/XKCD.pm',
    ABSTRACT_FROM       => 'lib/Bot/BasicBot/Pluggable/Module/XKCD.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'LWP::Simple' => 0,
	'URI::Title' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bot-BasicBot-Pluggable-Module-XKCD-*' },
);
