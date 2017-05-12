use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'Crypt::OpenSSL::Blowfish',
    VERSION_FROM        => 'Blowfish.pm',
    ABSTRACT_FROM       => 'Blowfish.pm', # retrieve abstract from module
    AUTHOR              => 'Vitaly Kramskikh <vkramskih@cpan.org>',
    LIBS                => ['-lcrypto'],   # e.g., '-lm'
    DEFINE              => '-DPERL5 -DOPENSSL_NO_KRB5',
);
