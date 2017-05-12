use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'CDB_File',
    'AUTHOR'        => 'Todd E Rinaldo <toddr@cpan.org>',
    'VERSION_FROM'  => 'CDB_File.pm',
    'ABSTRACT_FROM' => 'CDB_File.pm',
    'PL_FILES'      => {},
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
    ( ( $Config{'d_mmap'} && $Config{'d_mmap'} eq 'define' ) ? ( 'DEFINE' => '-DHASMMAP' ) : () ),
    PREREQ_PM => {
        'Test::More' => 0,    # For testing
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CDB_File-*' },
    META_MERGE => {
        recommends     => {},
        build_requires => {
            'Test::More' => 0,    # For testing
        },
        resources => {
            license  => 'http://dev.perl.org/licenses/',
            homepage => 'http://wiki.github.com/toddr/CDB_File',

            #            bugtracker => 'https://rt.cpan.org/Dist/Display.html?Queue=CDB_File',
            repository => 'https://github.com/toddr/CDB_File',

            #            MailingList => '',
        },
    },
);
