

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Data::Utilities',
    VERSION_FROM => 'lib/Data/Utilities.pm', # finds \$VERSION
    AUTHOR       => 'Hugo Cornelis (hugo.cornelis@gmail.com)',
    ABSTRACT     => 'General utilities for nested data structures.',
    PREREQ_PM    => {
		     'Clone' => 0.22,
                     'Test::Simple' => 0.44,
                    },
);
