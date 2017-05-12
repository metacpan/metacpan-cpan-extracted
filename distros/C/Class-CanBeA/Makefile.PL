use ExtUtils::MakeMaker;
WriteMakefile(
		NAME         => 'Class::CanBeA',
    META_MERGE => {
        license => 'other',
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-Class-CanBeA',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-Class-CanBeA/issues'
        }
    },
		VERSION_FROM => 'lib/Class/CanBeA.pm',
		PREREQ_PM    => {
		        # Storable           => 2.07,
		}
	     );
