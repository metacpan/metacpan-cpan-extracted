use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME' => 'DBIx::Repgen',
	      'VERSION_FROM' => 'Repgen.pm',
	      'PREREQ_PM' => {
			      DBI => 0.1,
			      'DBD::Sponge' => 0.1,
			     },
	      ($] >= 5.005 ? (ABSTRACT_FROM => 'Repgen.pm',
			      AUTHOR     => 'Anatoly K.Lasareff <tolik@aaanet.ru>'
			     ) : ()
	      ),
	     );
