use 5.012;
use Config;
use XS::Install;

my %params = (
    NAME             => 'CPP::panda::lib',
    CPLUS            => 14,
    SRC              => ['src'],
    INC              => '-Isrc',
    BIN_SHARE        => { INCLUDE => {'src' => '/'} },
    CCFLAGS          => '-Wall -Wextra',
    MIN_PERL_VERSION => '5.12.0',
    test             => { SRC => 't', BIN_DEPS => 'Test::Catch' },
);

if ($ENV{TEST_FULL}) {
    ($params{CCFLAGS}||='') .= ' -fsanitize=undefined';
    push @{$params{LIBS}||=[]}, '-lubsan'; #sanitizer
}

write_makefile(%params);
