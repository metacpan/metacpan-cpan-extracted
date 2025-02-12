#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'AWS::S3',
    VERSION_FROM     => 'lib/AWS/S3.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.10.1',
    PREREQ_PM => {
        'Moose'                      => '2.0',
        'MooseX::Types'              => 0,
        'MooseX::Types::URI'         => 0,
        'Class::Load'                => 0,
        'XML::LibXML'                => 0,
        'XML::LibXML::XPathContext'  => 0,
        'LWP::UserAgent::Determined' => 0,
        'Carp'                       => 0,
        'HTTP::Date'                 => 0,
        'HTTP::Headers'              => 6.07,
        'MIME::Base64'               => 0,
        'URI::Escape'                => 0,
        'Digest::HMAC_SHA1'          => 0,
        'Test::Deep'                 => 0,
        'JSON::XS'                   => 0,
        'LWP'             => 5.835,
        'Digest::SHA'     => '5.47',
        'URI'             => 1.59,
        'URI::QueryParam' => 0,
        'Date::Parse'     => 0,
      },
    BUILD_REQUIRES => {
        'Test::More'       => 0.31,
        'Test::Deep'       => 0.112,
        'Test::Exception'  => 0.32,
        'Data::Section::Simple' => 0,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/AWS-S3',
            bugtracker => 'https://github.com/leejo/AWS-S3/issues',
            repository => 'https://github.com/leejo/AWS-S3',
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
