#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 7;

{
  my $data = ptp([qw(--sort)], 'default_data.txt');
  is($data, "\n.\\+\nBe\nab/cd\nfoobar=\nfoobaz\nlast\nlast=\ntest\n",
     'sort');
}{
  my $data = ptp([qw(--ls)], 'default_data.txt');
  my @expected = ("", ".\\+", "ab/cd", "Be", "foobar=", "foobaz", "last", "last=", "test");
  {
    # The order may vary depending on the system, so let's not hard-code the
    # expected output here.
    use locale;
    @expected = sort @expected;
  }
  is($data, join("\n", @expected)."\n", 'local sort');
}

my $numeric_input = "20ab\n1d\n20.5\n99\nabc\n";

{
  my $data = ptp([qw(--sort)], \$numeric_input);
  is($data, "1d\n20.5\n20ab\n99\nabc\n", 'non numeric sort');
}{
  my $data = ptp([qw(--ns)], \$numeric_input);
  is($data, "abc\n1d\n20ab\n20.5\n99\n", 'numeric sort');
}

{
  my $data = ptp(['-C', '(reverse $a) cmp (reverse $b)', '--sort'],
                 'default_data.txt');
  is($data, "\n.\\+\nfoobar=\nlast=\nab/cd\nBe\nlast\ntest\nfoobaz\n",
     'custom sort');
}{
  my $data = ptp(['--cs', '(reverse $a) cmp (reverse $b)'],
                 'default_data.txt');
  is($data, "\n.\\+\nfoobar=\nlast=\nab/cd\nBe\nlast\ntest\nfoobaz\n",
     'custom sort');
}

{
  my $data = ptp([qw(--sort --unique)], \"abc\ndef\nabcd\nabc\ndef \ndef\n");
  is($data, "abc\nabcd\ndef\ndef \n", 'unique');
}
