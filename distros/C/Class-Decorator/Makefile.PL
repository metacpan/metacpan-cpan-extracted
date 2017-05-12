use ExtUtils::MakeMaker;
WriteMakefile(
	      'NAME'          => 'Class::Decorator',
	      'VERSION_FROM'  => 'Decorator.pm',
	      'PREREQ_PM'     => { Carp => undef },
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM => 'Decorator.pm',
		AUTHOR        => 'Nigel Wetters <nwetters@cpan.org>') : ())
);
