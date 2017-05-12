use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
    NAME                => 'Amazon::CloudFront::Thin',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Amazon/CloudFront/Thin.pm',
    ABSTRACT_FROM       => 'lib/Amazon/CloudFront/Thin.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'           => 0.88,
        'Carp'                 => 0,
        'LWP::Protocol::https' => 0,
        'URI'                  => 0,
        'HTTP::Message'        => 0,
        'Digest::SHA'          => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/Amazon-CloudFront-Thin/issues/',
            repository  => 'https://github.com/garu/Amazon-CloudFront-Thin',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Amazon-CloudFront-Thin-*' },
);

WriteMakefile( %options );
