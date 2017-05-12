use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Acme::Dice',
    VERSION_FROM => 'lib/Acme/Dice.pm', # finds \$VERSION
    AUTHOR       => 'Jim Bacon (jim@nortx.com)',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/Dice.pm', # retrieve abstract from module
       AUTHOR         => 'Jim Bacon <jim@nortx.com>') : ()),
);
