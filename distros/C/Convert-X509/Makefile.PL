#!/usr/bin/perl -w

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME          => 'Convert::X509',
    AUTHOR        => 'Leonid Cherepanov <grey.leo/gmail.com>',
    VERSION_FROM  => 'lib/Convert/X509.pm',
    PREREQ_PM     => {
        'Convert::ASN1'       => '0.22',
    },
);
