use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'DBIx::SQLstate',
    'VERSION_FROM'  => 'lib/DBIx/SQLstate.pm',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/DBIx/SQLstate.t t/DBIx/SQLstate/*.t',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/Perceptyx/perl-dbix-sqlstate.git',
                 web  => 'https://github.com/Perceptyx/perl-dbix-sqlstate',
             },
             bugtracker => {
                 web => 'https://github.com/Perceptyx/perl-dbix-sqlstate/issues'
             },
         },
    },
);
