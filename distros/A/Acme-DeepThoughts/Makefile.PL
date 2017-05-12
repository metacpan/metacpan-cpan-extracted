

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Acme::DeepThoughts',
    VERSION_FROM => 'lib/Acme/DeepThoughts.pm', # finds \$VERSION
    AUTHOR       => 'D. H. (PodMaster)',
    ABSTRACT     => 'Jack Handey does perl',
    PREREQ_PM    => {
                     'Text::Wrap' => 0,
                    },
);
