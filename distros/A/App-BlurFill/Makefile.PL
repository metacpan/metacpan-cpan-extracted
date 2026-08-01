use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'App::BlurFill',
    VERSION_FROM => 'lib/App/BlurFill.pm',
    LICENSE      => 'perl',
    AUTHOR       => 'dave@perlhacks.com',
    ABSTRACT     => 'Blurred background fill image processor',
    PREREQ_PM    => {
        'Imager'            => 0,
        'Imager::File::PNG' => 0,
        'File::Basename'    => 0,
        'File::Temp'        => 0,
        'Getopt::Long'      => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    MIN_PERL_VERSION => '5.040',
    EXE_FILES        => [ 'bin/blurfill' ],
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/davorg-cpan/app-blurfill.git',
                web  => 'https://github.com/davorg-cpan/app-blurfill',
            },
            bugtracker => {
                web  => 'https://github.com/davorg-cpan/app-blurfill/issues',
            },
        },
    },
);
