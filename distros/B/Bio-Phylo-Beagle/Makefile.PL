use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'       => 'Rutger Vos <rutgeraldo@gmail.com>',
    'NAME'         => 'Bio::Phylo::Beagle',
    'ABSTRACT'     => 'wrapper around Beagle-lib',
    'VERSION_FROM' => 'lib/Bio/Phylo/Beagle.pm',
    'OBJECT'       => 'beagle_wrap.o',
    'INC'          => `pkg-config --cflags hmsbeagle-1`,
    'LDFROM'       => 'beagle_wrap.o ' . `pkg-config --libs hmsbeagle-1`,
);