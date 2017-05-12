#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Archive::Peek',
    VERSION_FROM => 'lib/Archive/Peek.pm',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    ABSTRACT     => 'Peek into archives without extracting them',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Archive::Tar'               => '0',
        'Archive::Zip'               => '0',
        'Moose'                      => '0',
        'MooseX::Types::Path::Class' => '0',
        'Test::More'                 => '0',
    }
);

