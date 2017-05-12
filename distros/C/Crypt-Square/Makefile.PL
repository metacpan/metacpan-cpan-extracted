use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Crypt::Square',
    'VERSION_FROM' => 'Square.pm',
    'PREREQ_PM' => {},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

