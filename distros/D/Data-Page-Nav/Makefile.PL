use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME             => 'Data::Page::Nav',
    ABSTRACT         => 'Module for pages navigation',
    AUTHOR           => 'Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>',
    VERSION_FROM     => 'lib/Data/Page/Nav.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.008001',
 
    META_MERGE => {
        'meta-spec' => {
          version => 2,
        },
 
        resources => {
            homepage => 'https://github.com/ltmbr/Data-Page-Nav',
 
            bugtracker => {
                web => 'https://github.com/ltmbr/Data-Page-Nav/issues'
            },
 
            repository => {
                type => 'git',
                url  => 'git@github.com:ltmbr/Data-Page-Nav.git',
                web  => 'https://github.com/ltmbr/Data-Page-Nav'
            }
        }
    },
 
    PREREQ_PM => {
        'base'       => 0,
        'Data::Page' => '2.02'
    },
    
    TEST_REQUIRES => {
        'Test::More' => 0
    },    
 
    test => {
        TESTS => 't/*.t'
    }
);
