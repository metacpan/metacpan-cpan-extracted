#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CPAN::Metadata::RDF',
    VERSION_FROM => 'lib/CPAN/Metadata/RDF.pm',
    ABSTRACT     => 'Generate metadata about CPAN in RDF',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'DateTime'                => '0.01',
        'DBD::SQLite'             => '0.01',
        'DBI'                     => '0.01',
        'Digest::MD5'             => '0.01',
        'File::Find::Rule'        => '0.01',
        'File::Type'              => '0.01',
        'Path::Class'             => '0.01',
        'RDF::Simple::Serialiser' => '0.01',
        'Test::More'              => '0.01',
    },
);
