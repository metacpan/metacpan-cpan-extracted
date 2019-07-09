use 5.024001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'API::INSEE::Sirene',
    VERSION_FROM      => 'lib/API/INSEE/Sirene.pm',
    PREREQ_PM         => { 'JSON' => 2.90, 'LWP::UserAgent' => 6.15, 'POSIX' => 1.65 },
    ABSTRACT_FROM     => 'lib/API/INSEE/Sirene.pm',
    AUTHOR            => 'FOUQUET Justin <jfouquet at lncsa dot fr>',
    LICENSE           => 'perl',
);
