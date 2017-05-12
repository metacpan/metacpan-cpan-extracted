use 5.014002;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME          => 'App::yajg',
    LICENSE       => 'perl',
    AUTHOR        => 'Grigoriy Koudrenko <gragory.mail@gmail.com>',
    VERSION_FROM  => 'lib/App/yajg.pm',
    ABSTRACT_FROM => 'lib/App/yajg.pm',
    EXE_FILES     => ['bin/yajg'],
    PREREQ_PM     => {
        'Data::Dumper' => 0,
        'Getopt::Long' => 0,
        'JSON'         => 0,
        'Pod::Find'    => 0,
        'Pod::Usage'   => 0,
        'Test::More'   => 0,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            repository => 'https://bitbucket.org/gragory/app-yajg',
        },
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    MAN1PODS => {
        'lib/App/yajg.pm' => 'blib/man1/yajg.1',
    },
);
