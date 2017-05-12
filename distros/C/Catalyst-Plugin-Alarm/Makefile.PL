use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Catalyst::Plugin::Alarm',
    VERSION_FROM => 'Alarm.pm',
    PREREQ_PM    => {
        'Sys::SigAction'        => 0.11,
        'Time::HiRes'           => 1.0,
        'Class::Accessor::Fast' => 0,
        'Catalyst::Runtime'     => 5.8,
        'MRO::Compat'           => 0,

    },
    AUTHOR => 'Peter Karman <karman@cpan.org>',
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Catalyst-Plugin-Alarm-*' },

);
