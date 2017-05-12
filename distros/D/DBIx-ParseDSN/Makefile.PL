use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DBIx::ParseDSN',
    AUTHOR              => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    VERSION_FROM        => 'lib/DBIx/ParseDSN.pm',
    ABSTRACT_FROM       => 'lib/DBIx/ParseDSN.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'DBI'                       => '1.628',
        'Test::FailWarnings'        => '0.008',
        'Test::Most'                => '0.31',
        'Test::Perl::Critic'        => '1.02',
        'Test::Pod'                 => '1.48',
        'Test::Pod::Coverage'       => '1.08',
        'URI'                       => '1.60',
        'utf8::all'                 => '0.011',
        'Class::Load'               => '0.20',
        'Module::Load::Conditional' => '0.54',
        'Moo'                       => '1.004002',
        'MooX::Aliases'             => '0.001000',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DBIx-ParseDSN-*' },
);
