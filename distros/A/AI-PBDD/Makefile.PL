use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'AI::PBDD',
    VERSION_FROM => 'lib/AI/PBDD.pm',
    C => ['XS.c'],
    OBJECT => 'XS.o',
    INC => "-I$ENV{BUDDYPATH}/include/ -I$ENV{BUDDYPATH}/src/",
    LIBS => "-L$ENV{BUDDYPATH}/lib -lbdd -lm",
    LDDLFLAGS => "-fPIC -shared",
    LD => 'g++',
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/AI/PBDD.pm',
       AUTHOR         => 'Gianluca Torta <torta@di.unito.it>') : ()),
);
