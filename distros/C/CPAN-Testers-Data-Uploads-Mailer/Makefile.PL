#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::Data::Uploads::Mailer',
    VERSION_FROM        => 'lib/CPAN/Testers/Data/Uploads/Mailer.pm',
    ABSTRACT            => 'Verify CPAN uploads and mails reports',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Email::Simple'     => 0,
        'File::Basename'    => 0,
        'File::Path'        => 0,
        'File::Slurp'       => 0,
        'Getopt::ArgvFile'  => 0,
        'Getopt::Long'      => 0,
        'IO::File'          => 0,
        'Template'          => 0,
        'Time::Piece'       => 0,

        # build/test prereqs
        'Test::More'        => '0.70',
        'Test::Trap'        => '0'

    }
);
