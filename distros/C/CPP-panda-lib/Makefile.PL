use 5.018;
use Config;
use Panda::Install;

my %params = (
    NAME          => 'CPP::panda::lib',
    VERSION_FROM  => 'lib/CPP/panda/lib.pm',
    ABSTRACT_FROM => 'lib/CPP/panda/lib.pod',
    CPLUS         => 11,
    SRC           => ['src'],
    INC           => '-Isrc',
    BIN_SHARE     => {
        CPLUS    => 11,
        INCLUDE  => {'src' => '/'},
    },
    BIN_DEPS => ['CPP::catch::test'],
    CCFLAGS  => '-Wall -Wextra',
    OPTIMIZE  => '-g0 -O2',
    #OPTIMIZE  => '-g0',
    XS => {},
    #CC => 'clang++',
);

if ($ENV{TEST_FULL}) {
    ($params{DEFINE}||='') .= ' -DTEST_FULL';
    push @{$params{SRC}||=[]}, 't';
    $params{XS}{'t/xs.xs'} = 't/xs.cc';
    ($params{CCFLAGS}||='') .= ' -fsanitize=undefined';
    push @{$params{LIBS}||=[]}, '-lubsan'; #sanitizer
}

write_makefile(%params);

