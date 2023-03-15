#!perl
use Test2::V0;
use Test2::Tools::Command;
local @Test2::Tools::Command::command = ( $^X, '--', './bin/scalemogrifier' );

command { stdout => "c d e f g a b c'\n", };
command {
    args   => [qw(--mode=minor --transpose=a)],
    stdout => "a b c d e f g a'\n",
};
command {
    args   => [qw(--raw)],
    stdout => "0 2 4 5 7 9 11 12\n",
};

done_testing 9
