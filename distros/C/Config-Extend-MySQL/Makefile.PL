use 5.006;  # read the CAVEATS if you really want a version that works on 5.5
use strict;
use warnings;
use ExtUtils::MakeMaker;


my @more_prereqs = ();
push @more_prereqs, "IO::String" => 0 if $] < 5.008;

WriteMakefile(
    NAME                => 'Config::Extend::MySQL',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Config/Extend/MySQL.pm',
    ABSTRACT_FROM       => 'lib/Config/Extend/MySQL.pm',
    PREREQ_PM => {
        # prereqs
        'Carp'                  => '0',
        'Config::Tiny'          => '0',
        'File::Basename'        => '0',
        'File::Read'            => '0',
        'File::Spec::Functions' => '0',
        'UNIVERSAL::require'    => '0',
        @more_prereqs,

        # build/test prereqs
        'Test::More'            => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Config-Extend-MySQL-*' },
);
