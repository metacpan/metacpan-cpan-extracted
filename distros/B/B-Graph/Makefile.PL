use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'B::Graph',
    'VERSION_FROM' => 'Graph.pm', # finds $VERSION
    'dist' => {COMPRESS => 'gzip -9', SUFFIX => 'gz'},
    'PREREQ_PM' => {'B' => 0},
);
