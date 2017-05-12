use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CPAN::Testers::Reports::Query::JSON',
    VERSION_FROM => 'lib/CPAN/Testers/Reports/Query/JSON.pm',
    PREREQ_PM    => {
        'Carp'                                => 0,
        'CPAN::Testers::WWW::Reports::Parser' => 0.02,
        'JSON::Any'                           => 0,
        'LWP::Simple'                         => 0,
        'Moose'                               => 0,
        'namespace::autoclean'                => 0.09,
        'Test::More'                          => 0,
        'File::Slurp'                         => 0,
        'version'                             => 0,
    },
);

