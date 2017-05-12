use ExtUtils::MakeMaker;

my $pm = 'lib/Convert/Moji.pm';
my $pod = 'lib/Convert/Moji.pod';
my $repo = 'https://github.com/benkasminbullock/Convert-Moji';

WriteMakefile (
    NAME => 'Convert::Moji',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.008001',
);
