use ExtUtils::MakeMaker;

my $opt = '-O3 -funroll-loops -fomit-frame-pointer -fschedule-insns2 -Os -fno-strength-reduce -Wall -pipe';

WriteMakefile(
    'NAME' => 'Crypt::TC18',
    'VERSION_FROM' => 'TC18.pm',
    'PREREQ_PM' => {},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'OPTIMIZE' => $opt,
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

