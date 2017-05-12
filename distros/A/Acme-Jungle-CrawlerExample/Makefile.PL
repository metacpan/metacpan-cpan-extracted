

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Acme::Jungle::CrawlerExample',
    VERSION_FROM => 'lib/Acme/Jungle/CrawlerExample.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes',
    ABSTRACT     => 'crawler test using Jungle',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Moose' => 0.44,
                     'Jungle' => 0,
                    },
);
