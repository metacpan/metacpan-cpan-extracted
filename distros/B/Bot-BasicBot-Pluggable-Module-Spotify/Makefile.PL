use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bot::BasicBot::Pluggable::Module::Spotify',
    AUTHOR              => 'Edoardo Sabadelli <edoardo@cpan.org>',
    VERSION_FROM        => 'lib/Bot/BasicBot/Pluggable/Module/Spotify.pm',
    ABSTRACT_FROM       => 'lib/Bot/BasicBot/Pluggable/Module/Spotify.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Bot::BasicBot::Pluggable' => 0,
        'Net::Spotify' => 0,
        'XML::TreePP' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bot-BasicBot-Pluggable-Module-Spotify-*' },
);
