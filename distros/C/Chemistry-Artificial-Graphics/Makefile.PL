use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Chemistry::Artificial::Graphics',
    'VERSION_FROM'	=> 'lib/Chemistry/Artificial/Graphics.pm', 
    'PREREQ_PM'		=> {qw(
        Chemistry::Artificial::SQL  0.01
    )}, 
);

