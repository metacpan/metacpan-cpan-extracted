use strict;
use warnings;

use Test::More;
use Time::HiRes ();

use lib 't/lib';
use TestDBIO::Child;

# TestDBIO::Child runs a child perl without a shell and without a pipe open,
# so that it works on Windows perls before 5.22. Tests rely on it never
# hanging: a child that does not end is killed at the time limit and the
# result says so.

{
  my $r = TestDBIO::Child::run_perl(code => '$| = 1; print "out\n"; print STDERR "err\n"; exit 3;',
    merge_stderr => 1);
  is $r->{output}, "out\nerr\n", 'stdout and, when asked, stderr are returned';
  is $r->{exit}, 3, 'the exit code is returned';
  ok !$r->{timed_out}, 'a child that ends is not reported as timed out';
}

{
  my $r = TestDBIO::Child::run_perl(code => 'print "args=@ARGV\n";', args => ['a', 'b c']);
  is $r->{output}, "args=a b c\n", 'arguments reach the script';
  is $r->{status}, 0, 'status is the raw wait status';
}

{
  my $start = Time::HiRes::time();
  my $r = TestDBIO::Child::run_perl(
    code    => '$| = 1; print "started\n"; sleep 30; print "never\n";',
    timeout => 0.5,
  );
  my $took = Time::HiRes::time() - $start;

  ok $r->{timed_out}, 'a sleeping child is reported as timed out';
  ok $took < 15, 'the child was ended at the limit, not left to finish its sleep'
    or diag "took $took s";
  is $r->{output}, "started\n", 'what it printed before the kill is kept';
  isnt $r->{status}, 0, 'a killed child has a non-zero status';
}

# Windows perls write a child's text-mode output with CRLF into the binary
# temp file; the result gives it back with "\n" line ends. The child here
# writes the bytes such a file holds there.
{
  local $TestDBIO::Child::CRLF = 1;
  my $r = TestDBIO::Child::run_perl(code => 'binmode STDOUT; print "a\r\nb\r\n";');
  is $r->{output}, "a\nb\n", 'a child that writes CRLF gives its output with \n line ends';
}

{
  local $TestDBIO::Child::CRLF = 0;
  my $r = TestDBIO::Child::run_perl(code => 'binmode STDOUT; print "a\r\nb\r\n";');
  is $r->{output}, "a\r\nb\r\n", 'where the child writes plain \n, a \r\n it printed stays';
}

done_testing;
