use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Cassandra::Client',
    AUTHOR           => q{Tom van der Woerdt <tvdw@cpan.org>},
    VERSION_FROM     => 'lib/Cassandra/Client.pm',
    ABSTRACT_FROM    => 'lib/Cassandra/Client.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'AnyEvent' => 0,
        'Compress::LZ4' => '0.20',
        'Compress::Snappy' => '0.23',
        'Test::More' => 0,
    },
    PREREQ_PM => {
        # Optional: AnyEvent, Compress::LZ4, Compress::Snappy
        'Clone' => '0.36',
        'Promises' => '0.94',
        'Ref::Util' => '0.008',
        'EV' => '4.0',
        'Sub::Current' => '0.02',
        'Net::SSLeay' => '1.63',
        'Devel::GlobalDestruction' => '0.11',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Cassandra-Client-*' },
);
