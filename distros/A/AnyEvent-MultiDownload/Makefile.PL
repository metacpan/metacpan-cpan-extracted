use strict;
use warnings;
use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME                => 'AnyEvent::MultiDownload',
    AUTHOR              => '扶凯 <iakuf@163.com>',
    EXE_FILES           => ['bin/md-request'],
    PL_FILES            => {},
    LICENSE             => "perl",
    DISTNAME            => 'AnyEvent-MultiDownload',
    VERSION_FROM        => 'lib/AnyEvent/MultiDownload.pm',
    PREREQ_PM => {
        'Test::More' => 0,
        'AE'    => 0,
        'EV'    => 0,
        'Moo'   => 0,
        'AnyEvent::HTTP'    => 2.21,
        'AnyEvent::Digest'  => '0.0.5',
        'List::Util'        => 0,
        'Asset::File'       => 0,
    },
    TEST_REQUIRES => {
        'Test::More'    => 0,
        'Test::TCP'     => 0,
        'HTTP::Server::Simple::CGI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-MultiDownload-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/iakuf/anyevent-multidownload',
        },
    },
);
