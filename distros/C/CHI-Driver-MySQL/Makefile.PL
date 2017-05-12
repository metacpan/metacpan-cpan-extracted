use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME => 'CHI::Driver::MySQL',
    AUTHOR => 'Adrian Crisan <adrian.crisan88@gmail.com>',
    LICENSE => 'artistic_2',
    ABSTRACT_FROM => 'lib/CHI/Driver/MySQL.pm',
    VERSION_FROM => 'lib/CHI/Driver/MySQL.pm',
    EXE_FILES => [qw(  )],
    META_MERGE => {
        resources => {
            bugtracker => 'https://github.com/crlcu/chi-driver-mysql/issues',
            homepage => 'https://github.com/crlcu/chi-driver-mysql',
            repository => 'https://github.com/crlcu/chi-driver-mysql.git',
        },
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'File::Find' => '0',
    },
    PREREQ_PM => {
        'CHI::Driver' => '0',
        'Encode' => '2.87',
        'Mojo::mysql' => '0.14'
    },
    test => {
        TESTS => "t/*.t"
    },
);
