package Array::Shuffle;

our $VERSION = '0.04';

use strict;
use warnings;

require XSLoader;
XSLoader::load('Array::Shuffle', $VERSION);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(shuffle_array shuffle_huge_array);

1;
__END__

=head1 NAME

Array::Shuffle - fast shuffling of arrays in-place

=head1 SYNOPSIS

  use Array::Shuffle qw(shuffle_array);
  shuffle_array(@a);

=head1 DESCRIPTION

This module provide some functions for shuffling arrays in-place
efficiently.

=head2 API

=over 4

=item shuffle_array @a

Shuffles the given array in-place using the Fisher-Yates algorithm that
is O(N).

This function is an order of magnitude faster than the shuffle
function from L<List::Util>.

Note: that was true a long, long, long time ago. If you are worried
about performance, you should check it for yourself.

In most cases you should probably use L<List::Utils/shuffle> instead
of this obscure module!

=item shuffle_huge_array @a

Shuffles the given array in-place using an algorithm that is O(NlogN)
but more cache friendly than Fisher-Yates. In some extreme cases, when
shuffling huge arrays that do not find in the available RAM it may
perform better.

You would like to do some benchmarking to find out which one is better
suited for your particular case.

=back

=head1 SEE ALSO

L<List::Util>.

The following thread on PerlMonks for a discussion on the topic:
L<http://perlmonks.org/?node_id=953607>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, 2021 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BENCHMARKS

Included in this package you can find the script samples/benchmark.pl
that compares the performance of the following shuffle algorithms and
implementations:

=over 4

=item pp

uses a Fisher Yates shuffle implemented in pure perl

=item ls

uses the C<shuffle> function from L<List::Util>

=item sa

uses the C<shuffle_array> method from this module

=item sha

uses the C<shuffle_huge_array> method from this module

=back

What follows is the output of this script running on an i386 virtual
machine with 64MB of RAM and several GB of swap running Ubuntu.

Note that the algorithms are selectively switched down when they
become too slow and in the C<sa> case, when it starts using swap
memory as at this point it just becomes unbearably slow.

  Generating array with 100 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     0:00     21  1416  5843  3076  5.6 benchmark.pl
        Rate    pp    lu   sha    sa
  pp   354/s    --  -77%  -94%  -94%
  lu  1534/s  333%    --  -73%  -73%
  sha 5697/s 1509%  271%    --   -0%
  sa  5697/s 1509%  271%    0%    --
  Generating array with 158 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     0:57     21  1416  5843  3212  5.8 benchmark.pl
        Rate    pp    lu   sha    sa
  pp   188/s    --  -83%  -95%  -95%
  lu  1109/s  489%    --  -69%  -72%
  sha 3618/s 1821%  226%    --  -10%
  sa  4003/s 2025%  261%   11%    --
  Generating array with 251 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     1:34     21  1416  5843  3212  5.8 benchmark.pl
        Rate    pp    lu   sha    sa
  pp   333/s    --  -76%  -94%  -95%
  lu  1365/s  310%    --  -77%  -78%
  sha 5843/s 1656%  328%    --   -7%
  sa  6263/s 1783%  359%    7%    --
  Generating array with 398 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     2:50     21  1416  5843  3224  5.8 benchmark.pl
        Rate    pp    lu    sa   sha
  pp   260/s    --  -79%  -92%  -94%
  lu  1227/s  371%    --  -61%  -72%
  sa  3176/s 1120%  159%    --  -28%
  sha 4402/s 1591%  259%   39%    --
  Generating array with 630 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     3:34     21  1416  5843  3224  5.8 benchmark.pl
        Rate    pp    lu    sa   sha
  pp   309/s    --  -80%  -95%  -95%
  lu  1540/s  398%    --  -74%  -75%
  sa  5966/s 1830%  287%    --   -1%
  sha 6054/s 1858%  293%    1%    --
  Generating array with 1000 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     4:24     21  1416  5843  3224  5.8 benchmark.pl
        Rate    pp    lu    sa   sha
  pp   214/s    --  -74%  -93%  -94%
  lu   823/s  285%    --  -73%  -77%
  sa  3000/s 1304%  265%    --  -16%
  sha 3583/s 1577%  336%   19%    --
  Generating array with 1584 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     4:47     21  1416  5979  3280  5.9 benchmark.pl
        Rate    pp    lu   sha    sa
  pp  76.9/s    --  -85%  -94%  -96%
  lu   526/s  584%    --  -58%  -71%
  sha 1245/s 1520%  137%    --  -31%
  sa  1796/s 2238%  242%   44%    --
  Generating array with 2511 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     5:08     21  1416  5979  3280  5.9 benchmark.pl
        Rate    pp    lu   sha    sa
  pp  48.1/s    --  -82%  -94%  -94%
  lu   271/s  464%    --  -66%  -67%
  sha  801/s 1565%  195%    --   -4%
  sa   834/s 1634%  207%    4%    --
  Generating array with 3981 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     5:29     21  1416  6111  3388  6.1 benchmark.pl
        Rate    pp    lu    sa   sha
  pp  48.0/s    --  -79%  -95%  -95%
  lu   228/s  375%    --  -75%  -78%
  sa   921/s 1818%  304%    --  -13%
  sha 1059/s 2105%  364%   15%    --
  Generating array with 6309 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     5:52     21  1416  6243  3508  6.3 benchmark.pl
        Rate    pp    lu    sa   sha
  pp  32.9/s    --  -77%  -93%  -94%
  lu   140/s  327%    --  -68%  -76%
  sa   445/s 1254%  217%    --  -24%
  sha  587/s 1684%  318%   32%    --
  Generating array with 10000 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     6:17     21  1416  6407  3608  6.5 benchmark.pl
        Rate    pp    lu    sa   sha
  pp  20.4/s    --  -68%  -92%  -95%
  lu  62.8/s  208%    --  -75%  -85%
  sa   254/s 1147%  305%    --  -38%
  sha  413/s 1925%  557%   62%    --
  Generating array with 15848 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     6:41     21  1416  6547  3880  7.0 benchmark.pl
        Rate    pp    lu    sa   sha
  pp  14.7/s    --  -76%  -94%  -96%
  lu  61.1/s  317%    --  -77%  -83%
  sa   263/s 1696%  331%    --  -25%
  sha  353/s 2307%  478%   34%    --
  Generating array with 25118 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     7:12     21  1416  7023  4288  7.8 benchmark.pl
        Rate    pp    lu    sa   sha
  pp  9.26/s    --  -74%  -94%  -95%
  lu  35.5/s  283%    --  -78%  -82%
  sa   161/s 1644%  355%    --  -20%
  sha  202/s 2081%  469%   25%    --
  Generating array with 39810 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     7:36     21  1416  7843  5052  9.2 benchmark.pl
        Rate    pp    lu   sha    sa
  pp  5.77/s    --  -74%  -94%  -95%
  lu  21.8/s  278%    --  -78%  -80%
  sha  100/s 1633%  358%    --   -6%
  sa   107/s 1749%  389%    7%    --
  Generating array with 63095 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     7:56     21  1416  8563  5888 10.7 benchmark.pl
        Rate    pp    lu   sha    sa
  pp  3.00/s    --  -72%  -94%  -95%
  lu  10.9/s  263%    --  -77%  -82%
  sha 46.7/s 1458%  329%    --  -23%
  sa  60.8/s 1927%  458%   30%    --
  Generating array with 100000 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     8:13     21  1416 10379  7524 13.7 benchmark.pl
        Rate    pp    lu    sa   sha
  pp  2.21/s    --  -51%  -89%  -92%
  lu  4.46/s  102%    --  -78%  -84%
  sa  20.5/s  831%  360%    --  -26%
  sha 27.8/s 1159%  522%   35%    --
  Generating array with 158489 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     8:31     21  1416 12919 10208 18.6 benchmark.pl
        Rate    pp    lu   sha    sa
  pp  1.59/s    --  -52%  -88%  -93%
  lu  3.31/s  108%    --  -76%  -85%
  sha 13.6/s  756%  311%    --  -37%
  sa  21.5/s 1254%  550%   58%    --
  Generating array with 251188 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     8:56     21  1416 16623 13692 24.9 benchmark.pl
         Rate    pp    lu   sha    sa
  pp  0.826/s    --  -69%  -88%  -94%
  lu   2.65/s  221%    --  -61%  -81%
  sha  6.73/s  714%  154%    --  -51%
  sa   13.6/s 1550%  414%  103%    --
  Generating array with 398107 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     9:16     28  1416 23611 20172 36.7 benchmark.pl
         Rate    pp    lu   sha    sa
  pp  0.714/s    --  -56%  -82%  -92%
  lu   1.64/s  130%    --  -59%  -82%
  sha  4.00/s  460%  144%    --  -55%
  sa   8.91/s 1148%  444%  123%    --
  Generating array with 630957 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+     9:44     45  1416 33775 30632 55.8 benchmark.pl
      s/iter    pp    lu   sha    sa
  pp    3.10    --  -59%  -77%  -92%
  lu    1.27  144%    --  -43%  -80%
  sha  0.725  328%   75%    --  -65%
  sa   0.255 1116%  398%  184%    --
  Generating array with 1000000 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    11:35   5038  1416 48455 34376 62.6 benchmark.pl
      s/iter  sha   sa
  sha   1.21   -- -64%
  sa   0.440 175%   --
  Generating array with 1584893 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    12:00   6007  1416 52551 32100 58.5 benchmark.pl
      s/iter  sha   sa
  sha   1.36   -- -53%
  sa   0.645 111%   --
  Generating array with 1995262 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    12:11   6382  1416 60603 34600 63.0 benchmark.pl
      s/iter  sha   sa
  sha   2.02   -- -65%
  sa   0.700 189%   --
  Generating array with 2511886 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    12:24   6885  1416 78959 35356 64.4 benchmark.pl
      s/iter  sha   sa
  sha   2.10   -- -61%
  sa   0.820 156%   --
  Generating array with 3162277 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    12:41   7331  1416 91631 35200 64.1 benchmark.pl
      s/iter  sha   sa
  sha   2.79   -- -56%
  sa    1.22 129%   --
  Generating array with 3981071 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    12:57   7918  1416 107735 35176 64.1 benchmark.pl
      s/iter  sha   sa
  sha   3.78   -- -62%
  sa    1.43 164%   --
  Generating array with 5011872 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    13:28   9455  1416 144447 34692 63.2 benchmark.pl
      s/iter  sha   sa
  sha   5.11   -- -48%
  sa    2.67  91%   --
  Generating array with 6309573 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    14:15  12666  1416 169923 35112 64.0 benchmark.pl
      s/iter  sha   sa
  sha   6.77   -- -69%
  sa    2.11 221%   --
  Generating array with 7943282 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    15:06  16655  1416 202131 35140 64.0 benchmark.pl
      s/iter  sha   sa
  sha   8.26   -- -66%
  sa    2.84 191%   --
  Generating array with 10000000 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    16:27  25072  1416 275291 34468 62.8 benchmark.pl
      s/iter sha
  sha   27.6  --
  Generating array with 12589254 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    18:10  32251  1416 326243 34044 62.0 benchmark.pl
      s/iter sha
  sha   46.9  --
  Generating array with 15848931 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    20:44  44029  1416 390395 33768 61.5 benchmark.pl
      s/iter sha
  sha   91.6  --
  Generating array with 19952623 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    25:26  69013  1416 536583 32964 60.1 benchmark.pl
      s/iter sha
  sha    330  --
  Generating array with 25118864 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    35:12 123761  1416 638223 33072 60.2 benchmark.pl
      s/iter sha
  sha    393  --
  Generating array with 31622776 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    50:09 248018  1416 766131 33504 61.0 benchmark.pl
      s/iter sha
  sha    499  --
  Generating array with 39810717 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    70:41 446728  1416 1058111 32608 59.4 benchmark.pl
      s/iter sha
  sha    388  --
  Generating array with 50118723 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+    86:00 603755  1416 1260863 32960 60.0 benchmark.pl
      s/iter sha
  sha    531  --
  Generating array with 63095734 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+   106:33 839278  1416 1516151 31488 57.4 benchmark.pl
      s/iter sha
  sha    816  --
  Generating array with 79432823 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+   141:37 1224208 1416 2099583 31336 57.1 benchmark.pl
      s/iter sha
  sha    970  --
  Generating array with 100000000 elements...
    PID TTY      STAT   TIME  MAJFL   TRS   DRS   RSS %MEM COMMAND
   2551 pts/0    S+   178:54 1625198 1416 2504775 30196 55.0 benchmark.pl
      s/iter sha
  sha   1282  --
  Generating array with 125892541 elements...
      s/iter sha
  sha   2268  --


=cut

