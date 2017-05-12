
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME         => 'Acme::Note',
    VERSION_FROM => 'lib/Acme/Note.pm',
    PREREQ_PM    => {
        'strict' => 0,
        ( 'warnings'         => 0, ) x !!( $] >= 5.006 ),
        ( 'warnings::compat' => 0, ) x !!( $] < 5.006 ),
        'Term::ANSIColor' => 0,

        # build_requires
        'Test::More' => 0,
    },
    ($] >= 5.005 ? (
            ABSTRACT_FROM => 'lib/Acme/Note.pod',
            AUTHOR        => 'Adriano R. Ferreira <ferreira@cpan.org>'
    ) : ()),
    ($EUMM_VERSION >= 6.30_01 ? (
            LICENSE    => 'perl',
    ) : ()),
    ($EUMM_VERSION > 6.4501 ? (
            META_MERGE => {
                'meta-spec' => { version => 2 },
                    prereqs => {
                    test => {
                        recommends => {
                            'Test::Pod'           => '1.18',
                            'Test::Pod::Coverage' => '1.04',
                        },
                    },
                },
                resources => {
                    repository => {
                        type       => 'git',
                        url        => 'git://github.com/aferreira/Acme-Note.git',
                        web        => 'https://github.com/aferreira/cpan-Acme-Note',
                    },
                }
            },
    ) : () ),

);
