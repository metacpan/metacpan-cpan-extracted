use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBD::BigQuery',
    AUTHOR           => ['C.J. Collier <cjac@google.com>'],
    VERSION_FROM     => 'lib/DBD/BigQuery.pm',
    ABSTRACT         => 'Perl DBI Driver for Google Cloud BigQuery with Async Support',
    LICENSE          => 'apache_2_0',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.96',
    },
    PREREQ_PM => {
        'DBI'                                 => '1.651',
        'Google::Auth'                        => '0.03',
        'Google::gRPC::Client'                => '0.03',
        'Google::Cloud::Bigquery::V2'         => '0.02',
        'Google::Cloud::BigQuery::Storage::V1'=> '0.02',
        'Protobuf'                            => '0.06',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBD-BigQuery-*' },
);
