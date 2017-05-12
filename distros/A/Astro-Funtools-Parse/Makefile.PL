use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Astro::Funtools::Parse',
    'VERSION_FROM'	=> 'Parse.pm', # finds $VERSION
    'PREREQ_PM'		=> {Data::LineBuffer => 0.01,
			    Test::More => 0.42,
			    Data::Dumper => 0,
			   }, # e.g., Module::Name => 1.1
);
