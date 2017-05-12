use 5.008006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Crypt::RC4::XS',
    VERSION_FROM      => 'lib/Crypt/RC4/XS.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Crypt/RC4/XS.pm',
       AUTHOR         => 'Hiroyuki OYAMA <oyama@module.jp>') : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
);
