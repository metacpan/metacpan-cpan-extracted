use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Wx::PodEditor',
    AUTHOR              => 'Renee Baecker <module@renee-baecker.de>',
    VERSION_FROM        => 'lib/App/Wx/PodEditor.pm',
    ABSTRACT_FROM       => 'lib/App/Wx/PodEditor.pm',
    EXE_FILES           => [ 'bin/podeditor.pl' ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Data::Dumper'        => 2.121,
        'Exporter'            => 5.58,
        'File::Basename'      => 2.74,
        'File::Spec'          => 0.87,
        'Test::More'          => 0,
        'Wx'                  => 0.87,
        'Wx::Perl::PodEditor' => 0.02,
        'YAML::Tiny'          => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App::Wx::PodEditor-*' },
);
