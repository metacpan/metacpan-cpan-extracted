use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Template::TemplateFlute',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Dancer/Template/TemplateFlute.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Template/TemplateFlute.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Dancer' => 0,
        'Template::Flute' => 0.0140,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/racke/Dancer-Template-TemplateFlute.git',
                web  => 'https://github.com/racke/Dancer-Template-TemplateFlute',
                bugtracker  => 'https://github.com/racke/Dancer-Template-TemplateFlute/issues',
            },
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Template-Template-Flute-*' },
);
