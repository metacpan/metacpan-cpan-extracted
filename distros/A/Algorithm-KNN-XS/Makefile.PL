use 5.006001;
use ExtUtils::MakeMaker;

my $CC = 'g++';

WriteMakefile(
    NAME              => 'Algorithm::KNN::XS',
    VERSION_FROM      => 'lib/Algorithm/KNN/XS.pm',
    BUILD_REQUIRES    => {
      'Alien::LibANN'  => '0.01000',
    },
    PREREQ_PM         => {
      'ExtUtils::XSpp' => '0.01000',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Algorithm/KNN/XS.pm',
       AUTHOR         => 'Stephan Conrad <conrad@stephanconrad.de>') : ()),
    LIBS              => ['-lANN'],
    DEFINE            => '',
    INC               => '-I.',
    OBJECT            => '$(O_FILES)',
    XSOPT             => '-C++ -hiertype',
    TYPEMAPS          => ['perlobject.map'],
    CC                => $CC,
    LD                => '$(CC)',
);

