use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Crypt::Khazad',
    'VERSION_FROM' => 'Khazad.pm',
    'PREREQ_PM' => {},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

