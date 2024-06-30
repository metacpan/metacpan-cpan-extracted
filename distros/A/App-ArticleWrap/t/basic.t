use Test::More;
use File::Spec::Functions;
use IPC::Open2;

sub test {
  my ($input, $expected, $description) = @_;
  local $/ = undef; # slurp
  # setup child process
  my $pid = open2(my $chld_out, my $chld_in, $^X, catfile("blib", "script", "article-wrap"));
  # print and read
  print $chld_in $input;
  close($chld_in);
  my $got = <$chld_out>;
  # reap zombie and retrieve exit status
  waitpid($pid, 0);
  my $child_exit_status = $? >> 8;
  die "article-wrap failed with exist status $child_exit_status\n" if $child_exit_status;
  # test
  is($got, $expected, $description);
}

# line length is 72, short line length is 10
test("From: test\n\nHello!\n",
     "From: test\n\nHello!\n",
     "one line");
test("From: test\n\nThis is a very long line that definitely needs to be wrapped as soon as possible!\n",
     "From: test\n\nThis is a very long line that definitely needs to be wrapped as soon as\npossible!\n",
     "wrap one long line between two words");
test("From: test\n\nThis is a very long line that really needs to be wrapped as soon as possible!\n",
     "From: test\n\nThis is a very long line that really needs to be wrapped as soon as\npossible!\n",
     "wrap one long line with last word crossing the boundary");
test("From: test\n\nThis is a long line that needs to be wrapped as soon as possible, right!?\n",
     "From: test\n\nThis is a long line that needs to be wrapped as soon as possible,\nright!?\n",
     "wrap one long line with a punctuation beyond the boundary");
test("From: test\n\nHello!\nHello!\n",
     "From: test\n\nHello!\nHello!\n",
     "two short lines");
test("From: test\n\nHello, this is a long line.\nIt needs wrapping.\n",
     "From: test\n\nHello, this is a long line. It needs wrapping.\n",
     "two longer lines");
test("From: test\n\n> Hello, this is a long line.\n> It needs wrapping.\n",
     "From: test\n\n> Hello, this is a long line. It needs wrapping.\n",
     "two longer lines with prefix");

done_testing();
