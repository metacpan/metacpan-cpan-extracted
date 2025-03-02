use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

sub lines {
    my $re = join('', '\A', map("$_:.*\\n", @_), '\\z');
    qr/$re/;
}

$ENV{NO_COLOR} = 1;

like(run('--norc -ML 2 -n t/SAMPLE.txt')->stdout,
     lines(2), "-ML 2");

like(run('--norc -ML 2,4 -n t/SAMPLE.txt')->stdout,
     lines(2,4), "-ML 2,4");

like(run('--norc -ML 2:4 -n t/SAMPLE.txt')->stdout,
     lines(2..4), "-ML 2:4");

like(run('--norc -ML 2:+2 -n t/SAMPLE.txt')->stdout,
     lines(2..4), "-ML 2:+2");

like(run('--norc -ML -26:4 -n t/SAMPLE.txt')->stdout,
     lines(2..4), "-ML -26:4");

like(run('--norc -ML -26:+2 -n t/SAMPLE.txt')->stdout,
     lines(2..4), "-ML -26:+2");

like(run('--norc -ML :: -n t/SAMPLE.txt')->stdout,
     lines(1..28), "-ML ::");

like(run('--norc -ML :-8: -n t/SAMPLE.txt')->stdout,
     lines(1..28-8), "-ML :-8:");

like(run('--norc -ML ::2 -n t/SAMPLE.txt')->stdout,
     lines(map $_ * 2 - 1, 1..14), "-ML ::2");

like(run('--norc -ML 2::2 -n t/SAMPLE.txt')->stdout,
     lines(map $_ * 2, 1..14), "-ML 2::2");

# w/o -L
like(run('--norc -ML 1:5 11:15 21:25 -n t/SAMPLE.txt')->stdout,
     lines(1..5,11..15,21..25), "-ML 1:5 11:15 21:25");

done_testing;
