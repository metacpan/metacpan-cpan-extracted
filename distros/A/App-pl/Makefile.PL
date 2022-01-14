use ExtUtils::MakeMaker;

WriteMakefile
    NAME            => 'App::pl',
    AUTHOR          => 'Daniel Pfeiffer <occitan@esperanto.org>',
    LICENSE         => 'perl_5',
    VERSION_FROM    => 'pl',
    ABSTRACT        => 'Swiss Army Knife of Perl One-Liners',
    MIN_PERL_VERSION => '5.10.0',
    PREREQ_PM       => {},
    NO_MYMETA       => 1,
    META_ADD        => {
        distribution_type => 'script',
        prereqs => {
            runtime => {
                suggests => { 'Algorithm::Diff' => 0 }
            }
        },
        resources => {
            repository => {
                type => 'git',
                url => 'git://git.code.sf.net/p/perl1liner/code',
                web => 'https://git.code.sf.net/p/perl1liner/code'
            },
            homepage => 'https://perl1liner.sourceforge.io/'
        }
    };
