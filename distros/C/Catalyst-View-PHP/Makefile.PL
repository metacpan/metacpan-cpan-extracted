use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::View::PHP',
    AUTHOR    => 'Rusty Conover (rconover@infogears.com)',
    PREREQ_PM => {
        Catalyst        => '5.00',
	PHP::Interpreter => '1.00',
      },
    VERSION_FROM => 'lib/Catalyst/View/PHP.pm'
);
