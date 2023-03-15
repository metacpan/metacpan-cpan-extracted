#!perl
use Test2::V0;
use Test2::Tools::Command;
local @Test2::Tools::Command::command = ( $^X, '--', './bin/harmonic-fit' );

command {
    args   => [qw/c g/],
    stdout => "84\tc\n27\tg\n8\tf\n8\tais\n1\tcis\n1\tdis\n1\tgis\n"
};

done_testing
