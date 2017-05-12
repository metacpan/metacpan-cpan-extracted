#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    'PL_FILES'     => {},
    'INSTALLDIRS'  => 'site',
    'NAME'         => 'Compress::LZF_PP',
    'VERSION_FROM' => 'lib/Compress/LZF_PP.pm',
    'ABSTRACT'     => 'A pure-Perl LZF decompressor',
    'AUTHOR'       => 'Leon Brocard <acme@astray.com>',
    'LICENSE'      => 'perl',
    'PREREQ_PM'    => {
        'File::Slurp' => '0',
        'Test::More'  => '0',
    }
);

