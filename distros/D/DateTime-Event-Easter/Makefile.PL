use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DateTime::Event::Easter',
    VERSION_FROM => 'lib/DateTime/Event/Easter.pm', # finds $VERSION
    AUTHOR       => [ 'Rick Measham (rickm@cpan.org)', 'Jean Forget <JFORGET@cpan.org>' ],
    ABSTRACT     => 'Returns Easter events for DateTime objects',
    PREREQ_PM => {
                    'DateTime'         => 0.16,
		    'DateTime::Set'    => 0.08,
                    'Carp'             => 0,
                    'Params::Validate' => 0,
                    'DateTime::Calendar::Julian' => 0,
                 },
    'LICENSE'		=> 'perl',
    'MIN_PERL_VERSION' => '5.6.1',
);
