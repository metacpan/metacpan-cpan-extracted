use 5.018;
use Config;
use Panda::Install;

my %params = (
    NAME          => 'CPP::panda::lib',
    VERSION_FROM  => 'lib/CPP/panda/lib.pm',
    ABSTRACT_FROM => 'lib/CPP/panda/lib.pod',
    CPLUS         => 14,
    SRC           => ['src'],
    INC           => '-Isrc',
    BIN_SHARE     => {
        CPLUS    => 14,
        INCLUDE  => {'src' => '/'},
    },
    BIN_DEPS => ['CPP::catch::test'],
    CCFLAGS  => '-Wall -Wextra',
    OPTIMIZE  => '-g0 -O2',
    XS => {},
    #CC => 'clang++',
);

if ($ENV{TEST_FULL}) {
    ($params{DEFINE}||='') .= ' -DTEST_FULL';
    push @{$params{SRC}||=[]}, 't/src';
    $params{XS}{'lib.xs'} = 'lib.c';
    ($params{CCFLAGS}||='') .= ' -fsanitize=undefined';
    push @{$params{LIBS}||=[]}, '-lubsan'; #sanitizer
    ($params{BIN_SHARE}{CCFLAGS}||='') .= ' -fsanitize=undefined -fno-sanitize=alignment';
    push @{$params{BIN_SHARE}{LIBS}||=[]}, '-lubsan'; #sanitizer
}

write_makefile(%params);

