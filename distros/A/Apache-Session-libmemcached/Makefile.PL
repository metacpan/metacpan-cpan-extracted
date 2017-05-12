use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Apache::Session::libmemcached',
    AUTHOR              => 'Javier Uruen Val <jval@venda.com>',
    VERSION_FROM        => 'lib/Apache/Session/libmemcached.pm',
    ABSTRACT_FROM       => 'lib/Apache/Session/libmemcached.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Apache::Session' => 0,
        'Memcached::libmemcached' => 0,
        'Test::More' => 0,
        'Test::MockObject' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache-Session-libmemcached-*' },
);
