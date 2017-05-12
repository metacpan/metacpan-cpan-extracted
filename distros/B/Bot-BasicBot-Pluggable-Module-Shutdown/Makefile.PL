use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bot::BasicBot::Pluggable::Module::Shutdown',
    AUTHOR              => q{Michael Alexander <omni@cpan.org>},
    VERSION_FROM        => 'lib/Bot/BasicBot/Pluggable/Module/Shutdown.pm',
    ABSTRACT_FROM       => 'lib/Bot/BasicBot/Pluggable/Module/Shutdown.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Bot::BasicBot::Pluggable::Module' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bot-BasicBot-Pluggable-Module-Shutdown-*' },
);
