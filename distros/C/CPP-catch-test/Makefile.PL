use 5.018;
use Config;
use Panda::Install;

my %params = (
    NAME          => 'CPP::catch::test',
    CPLUS         => 11,
    SRC           => ['src'],
    INC           => '-Isrc',
    BIN_SHARE     => {
        CPLUS    => 11,
        INCLUDE  => {'src' => '/'},
    },
    CCFLAGS  => '-Wall -Wextra',
    OPTIMIZE  => '-g0 -O2',
    XS => {},
    #CC => 'clang++',
);

write_makefile(%params);

