use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'AnyEvent::POE_Reference',
    VERSION_FROM   => 'lib/AnyEvent/POE_Reference.pm',
    PREREQ_PM      => {
	Storable	=> 0,
	AnyEvent	=> 0,
	# Note that POE is not needed, here...
    },
    ABSTRACT_FROM  => 'lib/AnyEvent/POE_Reference.pm',
    AUTHOR         => 'Maxime Soule <btik-cpan@scoubidou.com>',
);
