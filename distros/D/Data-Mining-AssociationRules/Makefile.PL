use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Data::Mining::AssociationRules',
    VERSION_FROM => 'lib/Data/Mining/AssociationRules.pm', # finds $VERSION
    AUTHOR       => 'Dan Frankowski (dfrankow@winternet.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
