use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Array::PatternMatcher',
    'VERSION_FROM'	=> 'PatternMatcher.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Carp::Datum' => 0.1 }, # e.g., Module::Name => 1.1
);
