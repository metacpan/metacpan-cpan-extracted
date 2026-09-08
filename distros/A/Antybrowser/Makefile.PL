use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Antybrowser',
    AUTHOR           => 'Antybrowser.com <support@antybrowser.com>',
    VERSION_FROM     => 'lib/Antybrowser.pm',
    ABSTRACT_FROM    => 'lib/Antybrowser.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {
        'LWP::UserAgent' => 0,
        'JSON'           => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => { type => 'git', url => 'https://github.com/antybrowser/SDK', web => 'https://github.com/antybrowser/SDK' },
            homepage   => 'https://antybrowser.com',
            license    => 'https://opensource.org/licenses/MIT',
        },
    },
);
