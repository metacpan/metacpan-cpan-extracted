use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(
    NAME            => 'Apache::Pod',
    DISTNAME        => 'Apache-Pod',
    VERSION_FROM    => 'lib/Apache/Pod.pm',
    ABSTRACT_FROM   => 'lib/Apache/Pod.pm',
    PMLIBDIRS       => [qw(lib/)],
    AUTHOR          => 'Andy Lester <andy@petdance.com>',
    PREREQ_PM       => {
        'Apache::Constants' => 0,
        'File::Find'        => 0,
        'File::Spec'        => 0,
        'Pod::Find'         => '1.3',
        'Pod::Simple'       => '3.01',
        'Pod::Simple::HTML' => 0,
        'Pod::Simple::Text' => 0,
        'Test::More'        => 0,
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
);

