use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Crypt::Misty1',
    'VERSION_FROM' => 'Misty1.pm',
    'PREREQ_PM' => {},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

