#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::Common::Article',
    VERSION_FROM        => 'lib/CPAN/Testers/Common/Article.pm',
    ABSTRACT            => 'Parse a CPAN Testers NNTP article',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'Class::Accessor::Fast' => 0,
        'CPAN::DistnameInfo'    => 0,
        'Email::Simple'         => 0,
        'MIME::Base64'          => 0,
        'MIME::QuotedPrint'     => 0,
        'Time::Local'           => 0,

        # build/test prereqs
        'IO::File'              => '0',
        'Test::More'            => '0.70',

    }
);
