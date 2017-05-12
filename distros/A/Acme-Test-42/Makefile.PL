use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Acme::Test::42',
    'VERSION_FROM' => 'lib/Acme/Test/42.pm',
    ($] >= 5.005 ?
	(
            ABSTRACT_FROM => 'lib/Acme/Test/42.pm',
	    AUTHOR => 'Andrew Shitov <andy@shitov.ru>'
	)
	:
	()
    ),
    'PREREQ_PM' => {
        'Test::Builder' => 0,
    }
);
