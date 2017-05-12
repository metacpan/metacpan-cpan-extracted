use 5.008006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Crypt::Camellia_PP',
    VERSION_FROM      => 'lib/Crypt/Camellia_PP.pm',
    PREREQ_PM         => {
        'Crypt::CBC' => 2.13,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Crypt/Camellia_PP.pm', # retrieve abstract from module
       AUTHOR         => 'Hiroyuki OYAMA <oyama@module.jp>') : ()),
);
