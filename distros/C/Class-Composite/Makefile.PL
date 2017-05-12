use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => "Class::Composite",
    VERSION_FROM => 'lib/Class/Composite.pm',
    PREREQ_PM    => {
		     Scalar::Util         => 0.01,
		     Test::Simple         => 0.01,
		     Class::Base          => 0.03,
		    },
);
