use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(
    NAME            => 'Apache2::Pod',
    DISTNAME        => 'Apache2-Pod',
    VERSION_FROM    => 'lib/Apache2/Pod.pm',
    ABSTRACT_FROM   => 'lib/Apache2/Pod.pm',
    PMLIBDIRS       => [qw(lib/)],
    AUTHOR          => 'Theron Lewis <theron at theronlewis dot com>',
    PREREQ_PM       => {
        'Apache2::Const'    => 0,
        'File::Find'        => 0,
        'File::Spec'        => 0,
        'Pod::Find'         => '1.3',
        'Pod::Simple'       => '3.01',
        'Pod::Simple::HTML' => 0,
        'Pod::Simple::Text' => 0,
        'Test::More'        => 0,
        'URI::Escape'       => 0,
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
);

