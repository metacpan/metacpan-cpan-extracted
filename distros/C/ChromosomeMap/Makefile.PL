use ExtUtils::MakeMaker;

WriteMakefile(
        'NAME'            => 'Chromosome::Map',
        'VERSION_FROM'    => 'lib/Chromosome/Map.pm',
        'DISTNAME'        => 'ChromosomeMap',
        
        'PREREQ_PM'     => { 
            'GD'	    => '2.30', 
        },        
);
