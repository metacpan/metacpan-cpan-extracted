use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Benchmark::Timer::Class',
    'VERSION_FROM' => 'Class.pm', # finds $VERSION
);
