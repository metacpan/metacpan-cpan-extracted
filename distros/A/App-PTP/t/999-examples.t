#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 5;

{
  my $data = ptp(['-n',  'sprintf("%5d  %s", ++$i, $_)'],
                 'default_small.txt');
  is($data, "    1  foobar\n    2  foobaz\n    3  \n    4  last\n",
     'line count');
}{
  my $data = ptp(['-p',  'pf("%5d  %s", ++$i, $_) if $_'],
                 'default_small.txt');
  is($data, "    1  foobar\n    2  foobaz\n\n    3  last\n",
     'count non empty');
}{
  my $input = "User1:*:1\nOther:*:2\nLast User:password:3\n";
  my $data = ptp([qw(-F : --cut 1 --sort)], \$input);
  is($data, "Last User\nOther\nUser1\n", 'sorted user list');
}{
  my $data = ptp(['--eol', '-p', 'chomp if /=$/'], 'default_data.txt');
  is($data, "test\nfoobar=ab/cd\nBe\nfoobaz\n.\\+\n\nlast=last\n",
     'joined lines');
}{
  my $data =
      ptp([qw(-R . --input-filter /\.(c|h|cc)$/ -g ^\s*// --lc --pfn --pivot)]);
  is($data, "./src/fake.cc\t6\n./src/fake.h\t4\n", 'comment lines');
}
