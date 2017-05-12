use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::PKCS5',
    VERSION_FROM      => 'lib/Crypt/PKCS5.pm', # finds $VERSION
    PREREQ_PM         => {
        'Digest::MD5' => 0.0,
        'Digest::HMAC_SHA1' => 0.0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Crypt/PKCS5.pm', # retrieve abstract from module
       AUTHOR         => '小山浩之 <oyama@module.jp>') : ()),
);
