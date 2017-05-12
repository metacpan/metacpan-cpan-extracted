use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'CallGraph',
    'VERSION_FROM'	=> 'lib/CallGraph.pm', 
    'PREREQ_PM'		=> {
    },
    'EXE_FILES' => ['pflow'],
);
