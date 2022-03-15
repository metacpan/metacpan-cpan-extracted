use 5.008000;
use ExtUtils::MakeMaker;
use Crypt::OpenSSL::Guess qw(openssl_inc_paths openssl_lib_paths);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::OpenSSL::PKCS10',
    VERSION_FROM      => 'PKCS10.pm',
    PREREQ_PM         => { Crypt::OpenSSL::RSA => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'PKCS10.pm',
       AUTHOR         => 'JoNO <jonozzz@yahoo.com>') : ()),
    LIBS              => [openssl_lib_paths().' -lcrypto'],
    DEFINE            => '-DPERL5 -Wall',
    INC               => openssl_inc_paths(),
    
    'dist'  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    'clean' => { FILES    => 'Crypt-OpenSSL-PKCS10-*' },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
    (
        $ExtUtils::MakeMaker::VERSION >= 6.46
        ? (
            'META_MERGE' => {
                recommends => {
                    'Crypt::OpenSSL::Bignum' => 0,
                },
                configure_requires => {
                    'Crypt::OpenSSL::Guess' => '0.11',
                },
                build_requires => {
                    'Test' => 0,    # For testing
                },
                resources => {
                    'license'    => 'http://dev.perl.org/licenses/',
                    'homepage'   => 'https://metacpan.org/pod/Crypt::OpenSSL::PKCS10',
                    'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Crypt-OpenSSL-PKCS10',
                }
            }
          )
        : ()
    ),
);
