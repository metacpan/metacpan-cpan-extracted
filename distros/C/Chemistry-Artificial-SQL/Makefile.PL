use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Chemistry::Artificial::SQL',
    'VERSION_FROM'	=> 'lib/Chemistry/Artificial/SQL.pm', 
    'PREREQ_PM'		=> {qw(
        Chemistry::SQL          0.01
        Chemistry::Reaction     0.02
    )}, 
);

