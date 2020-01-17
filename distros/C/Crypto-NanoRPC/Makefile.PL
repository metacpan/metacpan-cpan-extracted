use 5.008001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Crypto::NanoRPC',
    VERSION_FROM      => 'lib/Crypto/NanoRPC.pm',
    PREREQ_PM         => {
                            JSON => 3.1,
                            HTTP::Request => 0,
                            LWP::UserAgent => 0,
                         },
    ABSTRACT_FROM     => 'lib/Crypto/NanoRPC.pm',
    AUTHOR            => 'ruben <ruben@hacktor.com>',
    LICENSE           => 'perl',
);
