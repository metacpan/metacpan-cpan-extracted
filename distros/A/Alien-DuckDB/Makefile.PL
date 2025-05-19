use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new( clean_install => 1, );

WriteMakefile(
    $abmm->mm_args(
        NAME               => 'Alien::DuckDB',
        DISTNAME           => 'Alien-DuckDB',
        AUTHOR             => 'Chris Prather <chris@prather.org>',
        VERSION_FROM       => 'lib/Alien/DuckDB.pm',
        ABSTRACT_FROM      => 'lib/Alien/DuckDB.pm',
        LICENSE            => 'perl',
        MIN_PERL_VERSION   => '5.008004',
        CONFIGURE_REQUIRES => {
            'Alien::Build::MM'    => '0.32',
            'Alien::Build'        => '0.32',
            'ExtUtils::MakeMaker' => '6.52',
            'Path::Tiny'          => '0.100',
            'Alien::cmake3'       => '0.08',
        },
        TEST_REQUIRES => {
            'Test::More'  => '0.94',
            'Test2::V0'   => '0',
            'Test::Alien' => '0.95',
            'Path::Tiny'  => '0.100',
        },
        PREREQ_PM => {
            'Alien::Base' => '0.038',
            'Path::Tiny'  => '0.100',
        },
        META_MERGE => {
            'meta-spec' => { version => 2 },
            resources   => {
                repository => {
                    type => 'git',
                    url  => 'https://github.com/perigrin/Alien-DuckDB.git',
                    web  => 'https://github.com/perigrin/Alien-DuckDB',
                },
                bugtracker => {
                    web => 'https://github.com/perigrin/Alien-DuckDB/issues',
                },
            },
        },
        clean => { FILES => 'Alien-DuckDB-* _alien' },
    )
);

sub MY::postamble {
    $abmm->mm_postamble(@_);
}

sub MY::install {
    $abmm->mm_install(@_);
}
