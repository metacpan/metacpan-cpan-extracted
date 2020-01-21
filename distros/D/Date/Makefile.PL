use strict;
use XS::Install;

my %params = (
    NAME          => 'Date',
    PREREQ_PM     => {'Export::XS' => 0},
    TEST_REQUIRES => {'Test::Exception' => 0},
    SRC           => [qw/src xs/],
    INC           => '-Isrc',
    CPLUS         => 11,
    PAYLOAD       => {'zoneinfo' => ''},
    BIN_DEPS      => ['XS::Framework', 'Export::XS'],
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra -Wno-implicit-fallthrough -Wno-unused-const-variable',
    test          => {
        SRC                  => 't',
        BIN_DEPS             => 'Test::Catch',
        RECURSIVE_TEST_FILES => 1,
    },
);

if ($ENV{SANITIZE}) {
    ($params{CCFLAGS}||='') .= ' -fsanitize=undefined -fsanitize=address -fno-omit-frame-pointer';
    $params{LIBS}[0] .= ' -lubsan -lasan'; #sanitizer
}

if ($ENV{DEV}) {
    my $postamble = '';
    my $gentype = "-G2";
    for (qw/parse-date.rl parse-relative.rl/) {
        my $file = "src/panda/date/$_";
        my $cfile = $file; $cfile =~ s/\.rl/.cc/;
        $postamble .= "parser : $cfile\n\n";
        $postamble .= "$cfile : $file\n".
                      "\t ragel -C $gentype $file -o $cfile\n\n";
    }
    $params{postamble} .= $postamble;
}

write_makefile(%params);
