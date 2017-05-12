use 5.004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Acme::Octarine',
    'VERSION_FROM'	=> 'Octarine.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Acme::Colour' => 0,
			    'Test::Simple' => 0,
			    'CPANPLUS' => 0.05,
			    'PadWalker' => 1.00,
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Octarine.pm', # retrieve abstract from module
       AUTHOR     => 'Nicholas Clark <nick@ccl4.org>') : ()),
);
