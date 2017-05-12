use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Bio::Metabolic',
    'VERSION_FROM' => 'lib/Bio/Metabolic.pm',    # finds $VERSION
    'PREREQ_PM'    => {
	Math::Symbolic => 0,
	Math::Fraction => 0,
	Math::Cephes => 0,
	PDL => 2.4,
        Test::More => 0,
    },                                           # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Bio/Metabolic.pm',    # retrieve abstract from module
            AUTHOR =>
              'Oliver Ebenhöh'
          )
        : ()
    ),
);
