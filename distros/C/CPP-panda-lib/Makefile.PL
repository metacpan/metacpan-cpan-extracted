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
    CCFLAGS  => '-Wall -Wextra',
    OPTIMIZE  => '-g0 -O2',
    #CC => 'clang++',
);

if ($ENV{TEST_FULL}) {
    ($params{DEFINE}||='') .= ' -DTEST_FULL';
    push @{$params{SRC}||=[]}, 't/src';
}

write_makefile(%params);

