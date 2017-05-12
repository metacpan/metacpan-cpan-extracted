use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Chemistry::SQL',
    'VERSION_FROM'	=> 'lib/Chemistry/SQL.pm', 
    'PREREQ_PM'		=> {qw(
        Chemistry::Mol          0.26
        Chemistry::File::SMILES 0.42
    )}, 
);

