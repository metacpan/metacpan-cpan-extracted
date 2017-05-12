

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Data::Pager',
    VERSION_FROM => 'lib/Data/Pager.pm', # finds \$VERSION
    AUTHOR       => 'Vidul Petrov (vidul@cpan.org)',
    ABSTRACT     => 'flexible data pager',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Test::More' => 0.01,
                    },
);
