use lib qw(inc); use Devel::AssertOS qw(Unix);

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'App::ptimeout',
    META_MERGE => {
        license => 'open_source',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-App-ptimeout',
            bugtracker => 'https://github.com/DrHyde/perl-modules-App-ptimeout/issues'
        }
    },
    VERSION_FROM => 'lib/App/ptimeout.pm',
    EXE_FILES    => [qw(
        bin/ptimeout
    )],
    PREREQ_PM    => {
        Capture::Tiny      => 0,
        Proc::ProcessTable => '0.634',
        Test::Differences  => 0,
        Test::More         => '0.88', # done_testing
    },
);
