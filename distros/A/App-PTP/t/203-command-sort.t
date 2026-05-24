#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 12;

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
  my $data = ptp([qw(--ss)], \"1.10.0\n1.2.0\n1.9.0\n");
  is($data, "1.2.0\n1.9.0\n1.10.0\n", 'semver sort');
}{
  # A pre-release version sorts before the corresponding release.
  my $data = ptp([qw(--ss)], \"1.1\n1.1-alpha1\n");
  is($data, "1.1-alpha1\n1.1\n", 'semver pre-release sort');
}{
  # Versions are grouped by their path-like prefix, then ordered by version
  # (the leading "v" is ignored and the major version is honored).
  my $data = ptp([qw(--ss)], \"ptp/v1.10\nptp/v1.2\nabc/v2.0\nabc/v1.0\n");
  is($data, "abc/v1.0\nabc/v2.0\nptp/v1.2\nptp/v1.10\n", 'semver prefix sort');
}{
  # A non-numeric core component is treated as 0 and triggers a warning.
  my ($data, $err) = ptp([qw(--ss)], \"abc\n1.0\n");
  is($data, "abc\n1.0\n", 'semver sort with a non-numeric value');
  like($err, qr/WARNING: version 'abc' has a non-numeric component 'abc'/,
       'semver sort warns about non-numeric values');
}

{
  my $data = ptp([qw(--sort --unique)], \"abc\ndef\nabcd\nabc\ndef \ndef\n");
  is($data, "abc\nabcd\ndef\ndef \n", 'unique');
}
