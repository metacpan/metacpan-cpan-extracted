

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Data::Transformer',
    VERSION_FROM => 'lib/Data/Transformer.pm', # finds \$VERSION
    AUTHOR       => 'Baldur Kristinsson (bk@mbl.is)',
    ABSTRACT     => 'Traverse a data structure, alter it in place',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
