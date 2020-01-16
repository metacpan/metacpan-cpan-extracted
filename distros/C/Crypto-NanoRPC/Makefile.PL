use 5.008001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Crypto::NanoRPC',
    VERSION_FROM      => 'lib/Crypto/NanoRPC.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
                            JSON => 3.1,
                            HTTP::Request => 0,
                            LWP::UserAgent => 0,
                         },
    ABSTRACT_FROM     => 'lib/Crypto/NanoRPC.pm', # retrieve abstract from module
    AUTHOR            => 'ruben <ruben@hacktor.com>',
    LICENSE           => 'perl',
);
