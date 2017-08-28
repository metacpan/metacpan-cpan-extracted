use 5.010001;
use ExtUtils::MakeMaker;

my $cflags = $ExtUtils::MakeMaker::Config{ccflags};
WriteMakefile(
    NAME              => 'DR::R',
    VERSION_FROM      => 'lib/DR/R.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/DR/R.pm',
    AUTHOR            => 'Dmitry E. Oboukhov <unera@>',
    LICENSE           => 'bsd2clause',
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I. -Irtree -Irtree/salad -Irtree/small',
    OBJECT            => '$(O_FILES)',
    CCFLAGS             => "$cflags -std=gnu99 -Wunused-variable",
);
