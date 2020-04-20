use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'App::pl',
    AUTHOR          => 'Daniel Pfeiffer <occitan@esperanto.org>',
    LICENSE         => 'perl_5',
    VERSION_FROM    => 'pl',
    ABSTRACT        => 'Swiss Army Knife of Perl One-Liners',
    MIN_PERL_VERSION => '5.10.0',
    NO_MYMETA       => 1,
    META_ADD        => {
        distribution_type => 'script',
        resources => {
            repository => {
                type => 'git',
                url => 'ssh://pfeiffer@git.code.sf.net/p/perl1liner/code',
                web => 'https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker'
            }
        }
    }
);
