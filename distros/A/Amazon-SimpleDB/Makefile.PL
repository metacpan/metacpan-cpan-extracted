#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Amazon::SimpleDB',
    VERSION_FROM => 'lib/Amazon/SimpleDB.pm',
    AUTHOR       => 'Timothy Appnel <tima@cpan.org>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'LWP::UserAgent'             => '0',
        'Digest::HMAC_SHA1'          => '0',
        'URI'                        => '0',
        'XML::Simple'                => '1.08',
        'Test::More'                 => '0.01', # for testing
    }
);
