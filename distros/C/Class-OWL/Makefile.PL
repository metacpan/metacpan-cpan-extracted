use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::OWL',
    AUTHOR              => 'Chris Prather <cpan@prather.org>',
    VERSION_FROM        => 'lib/Class/OWL.pm',
    ABSTRACT_FROM       => 'lib/Class/OWL.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Class::MOP' => 0,
        'XML::CommonNS' => 0,
        'RDF::Helper' => 0,
        'Data::Dumper' => 0,
        'LWP::Simple' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-OWL-*' },
);
