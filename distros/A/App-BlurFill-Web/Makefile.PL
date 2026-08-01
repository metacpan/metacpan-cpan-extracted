use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::BlurFill::Web',
    VERSION_FROM     => 'lib/App/BlurFill/Web.pm',
    LICENSE          => 'perl',
    AUTHOR           => 'dave@perlhacks.com',
    ABSTRACT         => 'Web interface for App::BlurFill',
    MIN_PERL_VERSION => '5.040',
    PREREQ_PM        => {
        'App::BlurFill' => '0.1.0',
        'Dancer2'       => 0,
        'File::Basename'=> 0,
        'File::Copy'    => 0,
        'File::Spec'    => 0,
        'File::Temp'    => 0,
        'Plack'         => 0,
        'Starman'       => 0,
    },
    TEST_REQUIRES => {
        'HTTP::Request::Common' => 0,
        'Plack::Test'           => 0,
        'Test::More'            => 0,
    },
    EXE_FILES => [ 'bin/app.psgi' ],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/davorg-cpan/app-blurfill-web.git',
                web  => 'https://github.com/davorg-cpan/app-blurfill-web',
            },
            bugtracker => {
                web => 'https://github.com/davorg-cpan/app-blurfill-web/issues',
            },
        },
    },
);
