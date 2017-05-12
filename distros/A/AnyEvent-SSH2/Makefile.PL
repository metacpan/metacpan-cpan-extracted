use strict;
use warnings;
use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME                => 'AnyEvent::SSH2',
    AUTHOR              => '扶凯 <iakuf@163.com>',
    PL_FILES            => {},
    LICENSE             => "perl",
    DISTNAME            => 'AnyEvent-SSH2',
    VERSION_FROM        => 'lib/AnyEvent/SSH2.pm',
    PREREQ_PM => {
        'Test::More' => 0,
        'AE'    => 0,
        'EV'    => 0,
        'Net::SSH::Perl'    => 0,
    },
    TEST_REQUIRES => {
        'Test::More'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-SSH2-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/iakuf/AnyEvent-SSH2',
            bugtracker => 'https://github.com/iakuf/AnyEvent-SSH2/issues',
            license    => 'http://dev.perl.org/licenses/',
        },
    },
);
