
use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Bot-BasicBot-Pluggable-Module-Retort',
  VERSION_FROM  => 'lib/Bot/BasicBot/Pluggable/Module/Retort.pm',
  PREREQ_PM     => {
      'Bot::BasicBot::Pluggable::Module' => 0,
      'Bot::BasicBot::Pluggable::Store'  => 0,
      'Text::English'                    => 0,
  },
  ABSTRACT_FROM => 'lib/Bot/BasicBot/Pluggable/Module/Retort.pm',
  AUTHOR        => 'Trevor Hall <wazzuteke@cpan.org>',
);
