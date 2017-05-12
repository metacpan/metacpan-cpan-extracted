use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Crypt::Noekeon',
    'VERSION_FROM' => 'Noekeon.pm',
    'PREREQ_PM' => {},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

