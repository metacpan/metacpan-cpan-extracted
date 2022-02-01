use 5.016003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'Crypt::PK::ECC::Schnorr',
    VERSION_FROM  => 'lib/Crypt/PK/ECC/Schnorr.pm', # finds $VERSION
    PREREQ_PM     => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM => 'lib/Crypt/PK/ECC/Schnorr.pm', # retrieve abstract from module
    AUTHOR        => 'Pavel Gulchuk <gul@gul.kiev.ua>',
    DEFINE        => '', # e.g., '-DHAVE_SOMETHING'
    INC           => '-I.', # e.g., '-I. -I/usr/include/other'
    PREREQ_PM     => {
        "Crypt::PK::ECC" => 0,
        "Math::GMPz"     => 0,
        "Digest::SHA"    => 0,
    },
);
