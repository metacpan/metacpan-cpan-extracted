use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Dancer2::Plugin::TemplateFlute',
    VERSION_FROM   => 'lib/Dancer2/Plugin/TemplateFlute.pm',
    ABSTRACT_FROM  => 'lib/Dancer2/Plugin/TemplateFlute.pm',
    AUTHOR         => 'Evan Brown (evan@bottlenose-wine.com)',
    BUILD_REQUIRES => {
        'aliased'       => 0,
        'JSON::MaybeXS' => 0,
        'Test::More'    => '0.94',    # subtest
        'Test::Deep'    => 0,
        'Test::Fatal'   => 0,
    },
    PREREQ_PM => {
        'Carp'             => 0,
        'Dancer2'          => '0.200000',
        'Dancer2::Plugin'  => 0,
        'Dancer2::Template::TemplateFlute' => '0.201',
        'Hash::MultiValue' => '0.12',
        'Moo'              => '2.000000',
        'namespace::clean' => 0,
        'Type::Tiny'       => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url => 'https://github.com/interchange/Dancer2-Plugin-TemplateFlute.git',
                web => 'https://github.com/interchange/Dancer2-Plugin-TemplateFlute',
                bugtracker => 'https://github.com/interchange/Dancer2-Plugin-TemplateFlute/issues',
            },
            IRC => 'irc://irc.perl.org/#dancer',
        },
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-TemplateFlute-*' },

);
