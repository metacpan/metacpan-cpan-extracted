use 5.020;
use Panda::Install;

write_makefile(
    NAME     => 'Boost::UUID',
    BIN_DEPS => ['Panda::XS', 'CPP::Boost::Mini' ],
    CCFLAGS  => '-Wall -Wextra',
    OPTIMIZE => '-O2',
    #CC       => 'clang++',
);
