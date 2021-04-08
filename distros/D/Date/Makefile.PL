use strict;
use XS::Install;

my $cmake_project = "panda-date";
my $cmake_tests   = "$cmake_project-tests";

my %params = (
    NAME          => 'Date',
    PREREQ_PM     => {'Export::XS' => 0},
    TEST_REQUIRES => {'Test::Exception' => 0},
    SRC           => 'src xs',
    INC           => '-Isrc',
    CPLUS         => 11,
    CCFLAGS       => '-Wall -Wextra',
    PAYLOAD       => {'clib/zoneinfo' => '/zoneinfo'},
    BIN_DEPS      => ['XS::Framework', 'Export::XS'],
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CLIB          => {
        DIR          => 'clib',
        CMAKE_TARGET => $cmake_project,
        FILE         => "lib${cmake_project}.a",
    },
    test          => {
        SRC                  => 't',
        BIN_DEPS             => 'Test::Catch',
        RECURSIVE_TEST_FILES => 1,
        CLIB                 => {
            DIR          => 'clib',
            CMAKE_TARGET => "${cmake_tests}",
            FILE         => "lib${cmake_tests}.a",
        },
    },
);

write_makefile(%params);
