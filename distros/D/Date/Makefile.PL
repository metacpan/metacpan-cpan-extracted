use strict;
use XS::Install;

my %params = (
    NAME          => 'Date',
    PREREQ_PM     => {'Export::XS' => 0},
    TEST_REQUIRES => {'Test::Exception' => 0},
    SRC           => [qw/src xs/],
    INC           => '-Isrc',
    CPLUS         => 11,
    BIN_DEPS      => 'Time::XS',
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
);

if ($ENV{SANITIZE}) {
    ($params{CCFLAGS}||='') .= ' -fsanitize=undefined -fsanitize=address -fno-omit-frame-pointer';
    $params{LIBS}[0] .= ' -lubsan -lasan'; #sanitizer
}

write_makefile(%params);
