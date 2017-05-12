#!perl -w
use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
    MIN_PERL_VERSION => '5.012', # Well, that's what the source code says
    NAME                => 'Apache::Tika::Async',
    AUTHOR              => q{Max Maischein <corion@cpan.org>},
    VERSION_FROM        => 'lib/Apache/Tika/Async.pm',
    ABSTRACT_FROM       => 'lib/Apache/Tika/Async.pm',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/Corion/apache-tika',
        },
    },
    BUILD_REQUIRES => {
        'Exporter'   => '5',    # we need the "import" facility
        'Carp'       => '0',

        # Fairly long in core
        'File::Path' => 0,
        'File::Copy' => 0,
        'File::Find' => 0,
        'File::Basename' => 0,
    },
    'NAME' => 'Apache::Tika::Async',
    'LICENSE' => 'perl',
    'PREREQ_PM' => {
        'Carp' => 0,
        'Exporter' => 5,
        'Promises' => 0,
        'LWP::UserAgent' => 6,
        'Moo' => 0,
        'JSON::XS' => 0,
    },
);
