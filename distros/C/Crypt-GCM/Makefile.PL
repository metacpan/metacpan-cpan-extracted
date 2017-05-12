use 5.008006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Crypt::GCM',
    VERSION_FROM      => 'lib/Crypt/GCM.pm',
    PREREQ_PM         => {
        'Crypt::Rijndael' => 0.04,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Crypt/GCM.pm',
       AUTHOR         => 'Hiroyuki OYAMA <oyama@module.jp>') : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
);
