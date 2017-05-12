use 5.008006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Crypt::CCM',
    VERSION_FROM      => 'lib/Crypt/CCM.pm',
    PREREQ_PM         => {
        'Crypt::Rijndael' => 0.0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Crypt/CCM.pm',
       AUTHOR         => 'Hiroyuki OYAMA <oyama@module.jp>') : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
);
