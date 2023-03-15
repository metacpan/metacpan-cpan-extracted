#!perl
use Test2::V0;
use Test2::Tools::Command;
local @Test2::Tools::Command::command = ( $^X, '--', './bin/varionator' );

command {
    args   => [qw(I V)],
    stdout => "I V\n",
};

command {
    args   => [ "I", "(II IV)" ],
    stdout => "I II\nI IV\n",
};

command {
    args   => [ "c", "(d f a)", "(g e b)", "c" ],
    stdout =>
      "c d g c\nc d e c\nc d b c\nc f g c\nc f e c\nc f b c\nc a g c\nc a e c\nc a b c\n",
};

done_testing 9
