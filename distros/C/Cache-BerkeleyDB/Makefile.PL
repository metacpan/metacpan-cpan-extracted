

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Cache::BerkeleyDB',
    VERSION_FROM => 'lib/Cache/BerkeleyDB.pm', # finds \$VERSION
    AUTHOR       => 'Baldur Kristinsson (bk@mbl.is)',
    ABSTRACT     => 'implements the Cache::Cache interface',
    PREREQ_PM    => {
                     'Test::Simple' => '0.44',
					 'Cache::Cache' => '1.00',
					 'BerkeleyDB'   => '0.21',
                    },
);
