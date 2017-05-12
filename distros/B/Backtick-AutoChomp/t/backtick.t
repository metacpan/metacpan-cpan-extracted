#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 17;

my $CMD='echo 2008';
my $normal = `$CMD`;
my $chomped = $normal;
chomp($chomped);
my $s;

like($normal, qr/^2008$/, "got echo result");
isnt($chomped, $normal, "chomped");

$s = qx/$CMD/;
is($s,$normal,"qx matches backtick");

use Backtick::AutoChomp;

$s=`$CMD`;
is($s, '2008', '[chomp/backtick] number');
is(`$CMD`,'2008', '[chomp/backtick] direct number');
is(4016/`$CMD`,'2', '[chomp/backtick] denominator');
is(`$CMD`/1004,'2', '[chomp/backtick] numerator');
is("foo".`$CMD`."bar",'foo2008bar', '[chomp/backtick]str cat');

$s=qx{$CMD};
is($s, '2008', '[chomp/qx] number');
is(qx{$CMD},'2008', '[chomp/qx] direct number');
is(4016/qx{$CMD},'2', '[chomp/qx] denominator');
is(qx{$CMD}/1004,'2', '[chomp/qx] numerator');
is("foo".qx{$CMD}."bar",'foo2008bar', '[chomp/qx] str cat');

no Backtick::AutoChomp;
$s=`$CMD`;
is($s, "2008\n", '[nochomp/backtick] number');
is(`$CMD`,"2008\n", '[nochomp/backtick] direct number');
 
$s=qx{$CMD};
is($s, "2008\n", '[nochomp/qx] number');
is(qx{$CMD},"2008\n", '[nochomp/qx] direct number');

