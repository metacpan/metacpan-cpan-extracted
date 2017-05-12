use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Crypt::SEAL2',
    'VERSION_FROM' => 'SEAL2.pm',
    'PREREQ_PM' => {},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

