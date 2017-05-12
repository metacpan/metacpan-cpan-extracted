#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CPAN-IndexPod',
    VERSION_FROM => 'lib/CPAN/IndexPod.pm',
    ABSTRACT     => 'Index the POD from an unpacked CPAN',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Class::Accessor::Chained' => 0,
        'File::Find::Rule'         => 0,
        'KinoSearch'               => 0,
        'Pod::Simple'              => 0,
        'Test::More'               => 0,
    }
);
