use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Apache::Session::PHP',
    'VERSION_FROM' => 'lib/Apache/Session/PHP.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'Apache::Session' => 1.52,
	'PHP::Session' => 0.06,
    },
);
