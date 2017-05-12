
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME	    => 'Bot::ICB',
              VERSION_FROM  => 'lib/Bot/ICB.pm',
              PREREQ_PM     => { Net::ICB => 0 },
              ABSTRACT_FROM => 'lib/Bot/ICB.pm',
              AUTHOR        => 'Brian Moseley <bcm@maz.org>',
              );
