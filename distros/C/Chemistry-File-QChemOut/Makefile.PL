use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Chemistry::File::QChemOut',
    'VERSION_FROM'	=> 'QChemOut.pm', 
    'PREREQ_PM'		=> {
        'Chemistry::Mol'        => '0.24',
    },
);
