#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

if ( $^O eq 'MSWin32' || $^O eq 'solaris' ||  $^O eq 'cygwin' ) {
    print STDERR "OS unsupported: $^O\n";
    exit( 255 );
}

use ExtUtils::MakeMaker qw(
    prompt
);
use File::Spec::Functions qw(
    catdir
);

use Config;
use inc::Module::Install;
readme_from('lib/Confluent/SchemaRegistry.pm');

my %config = (
    NAME                => 'Confluent::SchemaRegistry',
    VERSION_FROM        => 'lib/Confluent/SchemaRegistry.pm',  # finds $VERSION
    MIN_PERL_VERSION    => '5.010',
    PREREQ_PM           => {            # more to the list $Module::CoreList::version{5.010}
		'JSON::XS'		=> '3.02',
		'REST::Client'	=> '273',
		'Try::Tiny'		=> '0.22',
		'Avro::Schema'	=> 0,
		'Aspect'		=> '1.04'
    },
    TEST_REQUIRES       => {            # more to the list $Module::CoreList::version{5.010}
		'Math::BigInt'				=> '1.89',
		'Test::Exception'			=> '0.43'
    },
    META_MERGE          => {
#        no_index                => {
#            directory               => [
#                't',
#                'inc',
#                'xt',
#                'tools',
#            ]
#        },
        'meta-spec'             => { version => 2 },
        resources               => {
            bugtracker              => {
               web                      => 'https://github.com/alivraghi/Confluent-SchemaRegistry/issues',
            },
            homepage                => 'https://github.com/alivraghi/Confluent-SchemaRegistry',
            repository              => {
                type                    => 'git',
                url                     => 'git@github.com/Confluent-SchemaRegistry.git',
                web                     => 'https://github.com/alivraghi/Confluent-SchemaRegistry.git',
            },
        },
    },
    ( $] >= 5.005 ?                             ## Add these new keywords supported since 5.005
        (
            ABSTRACT            => 'A simple client for interacting with Confluent Schema Registry.',
            AUTHOR              => 'Alvaro Livraghi',
        ) : ()
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    realclean           => { FILES => "inc Confluent-SchemaRegistry-*.tar.gz" },
    LICENSE             => 'perl',
#    NO_MYMETA           => 1,
);

#my @patterns = qw( t/*.t );
#$config{test} = { TESTS => join ' ', map { glob } @patterns };
#
#if ( $ENV{AUTHOR_TESTS} ) {
#    @patterns = qw( xt/author/*.t );
#    $config{test}->{TESTS} .= ' '.join ' ', map { glob } @patterns;
#}
#
#if ( $ENV{RELEASE_TESTS} ) {
#    @patterns = qw( xt/release/*.t );
#    $config{test}->{TESTS} .= ' '.join ' ', map { glob } @patterns;
#}
#
#mkdir 't/data' unless -d 't/data';
#mkdir 'inc' unless -d 'inc';

ExtUtils::MakeMaker::WriteMakefile( %config );



