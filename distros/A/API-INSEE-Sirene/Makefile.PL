use 5.024001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'API::INSEE::Sirene',
    VERSION_FROM      => 'lib/API/INSEE/Sirene.pm',
    MIN_PERL_VERSION  => '5.024001',
    PREREQ_PM         => {
        'HTTP::Request::Common' => 6.18,
        'HTTP::Status'          => 6.18,
        'JSON'                  => 2.90,
        'LWP::UserAgent'        => 6.15,
        'POSIX'                 => 1.65,
        'Switch'                => 2.17,
    },
    ABSTRACT_FROM     => 'lib/API/INSEE/Sirene.pm',
    AUTHOR            => 'FOUQUET Justin <jfouquet at lncsa dot fr>',
    LICENSE           => 'perl_5',

    clean             => { FILES => "MANIFEST API-INSEE-Sirene-*.tar.gz debian.bak debian/libapi-insee-sirene-perl*" },
);
