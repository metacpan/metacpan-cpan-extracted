use 5.018;
use Config;
use XS::Install;

my %params = (
    NAME          => 'Data::Recursive',
    TEST_REQUIRES => {'Test::Exception' => 0},
    CPLUS         => 11,
    SRC           => ['src'],
    INC           => '-Isrc',
    BIN_DEPS      => ['Export::XS', 'XS::Framework'],
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
);

write_makefile(%params);
