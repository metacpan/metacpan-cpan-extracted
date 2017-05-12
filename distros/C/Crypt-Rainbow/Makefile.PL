use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Crypt::Rainbow',
    'VERSION_FROM' => 'Rainbow.pm',
    'PREREQ_PM' => {},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

