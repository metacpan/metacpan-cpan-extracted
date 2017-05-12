use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Acme::Current::Forever',
  VERSION_FROM => 'lib/Acme/Current/Forever.pm',
  PREREQ_PM => {
		'Test::More' => 0,
	       },
);
