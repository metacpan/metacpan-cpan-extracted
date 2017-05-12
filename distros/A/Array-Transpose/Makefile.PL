use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Array::Transpose',
    VERSION_FROM => 'lib/Array/Transpose.pm',
    AUTHOR       => 'Michael R. Davis (domain=>stopllc,tld=>com,account=>mdavis)',
    ABSTRACT     => 'Transposes a 2-Dimensional Array',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Exporter'     => 0,
                     'strict'       => 0,
                     'warnings'     => 0,
                     'vars'         => 0,
                    },
);
