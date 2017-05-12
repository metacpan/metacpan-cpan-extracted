use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::OpenSSL::PKCS10',
    VERSION_FROM      => 'PKCS10.pm',
    PREREQ_PM         => { Crypt::OpenSSL::RSA => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'PKCS10.pm',
       AUTHOR         => 'JoNO <jonozzz@yahoo.com>') : ()),
    LIBS              => ['-L/usr/local/ssl/lib -lcrypto'],
    DEFINE            => '-DPERL5 -Wall',
    INC               => '-I/usr/local/ssl/include',
);
