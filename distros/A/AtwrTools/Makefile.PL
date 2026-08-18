use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'AtwrTools',
    VERSION_FROM => 'lib/AtwrTools.pm',
    ABSTRACT => 'Scan and remove invisible Unicode characters from text.',
    AUTHOR => 'bbwdadfg <bbwdadfg@users.noreply.github.com>',
    LICENSE => 'mit',
    MIN_PERL_VERSION => '5.010',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage => 'https://aitextwatermarkremover.com/',
            repository => {
                type => 'git',
                url => 'https://github.com/bbwdadfg/aitextwatermarkremover-tools.git',
                web => 'https://github.com/bbwdadfg/aitextwatermarkremover-tools',
            },
        },
    },
);
