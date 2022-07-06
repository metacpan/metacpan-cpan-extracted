use Test::More;

for my $program ( "cat", "cut", "echo", "find", "git", "grep", "head", "ls", "mkdir", "rm", "sed", "sort", "tail", "uniq", "xargs" ) {
  is( system("which \"$program\" >/dev/null 2>/dev/null"), 0, "which $program" );
};

done_testing();

