use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::BenchmarkResults',
    'VERSION_FROM'	=> 'BenchmarkResults.pm', # finds $VERSION
    'AUTHOR'       => 'Jason Titus < jasontitus@tiltastech.com >',
    'PREREQ_PM'		=> { 'Statistics::Lite' => 1.02  }, # e.g., Module::Name => 1.1
);
