#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CPAN::Unpack',
    VERSION_FROM => 'lib/CPAN/Unpack.pm',
    ABSTRACT     => 'Unpack CPAN distributions',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Archive::Extract'            => 0,
        'Archive::Tar'                => 0,
        'Archive::Zip'                => 0,
        'Class::Accessor::Chained'    => 0,
        'IO::Zlib'                    => 0,
        'Parse::CPAN::Packages::Fast' => '0.04',
        'Test::More'                  => 0,
        'YAML::Any'                   => 0,
    },
);
