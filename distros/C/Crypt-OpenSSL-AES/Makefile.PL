use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::OpenSSL::AES',
    VERSION_FROM      => 'lib/Crypt/OpenSSL/AES.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Crypt/OpenSSL/AES.pm', # retrieve abstract from module
    AUTHOR            => 'Tolga Tarhan',
    DISTNAME          => 'Crypt-OpenSSL-AES',
    MIN_PERL_VERSION  => '5.008',
    LICENSE           => 'perl',
    LIBS              => ['-lcrypto'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    META_MERGE        => {
      "meta-spec" => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'git://github.com:perl-openssl/perl-Crypt-OpenSSL-AES.git',
          web => 'https://github.com/perl-openssl/perl-Crypt-OpenSSL-AES',
        },
      },
    },
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
