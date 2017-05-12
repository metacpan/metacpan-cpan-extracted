use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Apache2::REST',
    AUTHOR              => 'Jerome Eteve <jerome@eteve.net>',
    VERSION_FROM        => 'lib/Apache2/REST.pm',
    ABSTRACT_FROM       => 'lib/Apache2/REST.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/restclient' ],
    PREREQ_PM => {
        'Test::More' => 0,
        'Class::AutoAccess' => 0.02 ,
        'Apache2::Request' => 2.08 ,
        'Apache2::Log'     => 2.000001,
        'JSON::XS' => 2.2222 ,
        'XML::Simple' => 2.14 ,
        'YAML' => 0.68 ,
        'REST::Client' => 118,
        'HTTP::Status' => 1.28,
        'Digest::MD5' => 2.33,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache2-REST-*' },
);
