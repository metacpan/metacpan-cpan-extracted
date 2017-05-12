use strict;
use warnings;
use Test::Output qw(stdout_is);
use Test::More tests => 2;
use App::perlhl;

my $expected = do { local $/; <DATA> };

stdout_is(
    sub { App::perlhl->new('html')->run(undef, ('t/testfile')) },
    $expected,
    'HTML highlighting was done right'
);

my $system = `$^X bin/perlhl --html t/testfile 2>&1`;
is $system, $expected, 'perlhl does the same thing';

__DATA__
<span style="color:#399;font-style:italic;">#!/usr/bin/env perl</span>
<span style="color:#000;">use</span> <span style="color:#900;">strict</span><span style="color:#000;">;</span>
<span style="color:#000;">use</span> <span style="color:#900;">warnings</span><span style="color:#000;">;</span>

<span style="color:#000;">my</span> <span style="color:#080;">$scalar</span> <span style="color:#000;">=</span> <span style="color:#00a;">'</span><span style="color:#00a;">hello</span><span style="color:#00a;">'</span><span style="color:#000;">;</span>
<span style="color:#000;">my</span> <span style="color:#080;">$newline</span> <span style="color:#000;">=</span> <span style="color:#00a;">"</span><span style="color:#00a;"><span style="color:#800;">\n</span></span><span style="color:#00a;">"</span><span style="color:#000;">;</span>
<span style="color:#000;">my</span> <span style="color:#f70;">@array</span> <span style="color:#000;">=</span> <span style="color:#00a;">qw(</span><span style="color:#00a;">one two three</span><span style="color:#00a;">)</span><span style="color:#000;">;</span>
<span style="color:#000;">my</span> <span style="color:#080;">$string</span> <span style="color:#000;">=</span> <span style="color:#00a;">q{</span><span style="color:#00a;">Hello, world!</span><span style="color:#00a;">}</span><span style="color:#000;">;</span>
<span style="color:#000;">if</span> <span style="color:#000;">(</span><span style="color:#080;">$scalar</span><span style="color:#000;">)</span> <span style="color:#000;">{</span>
    <span style="color:#000;">my</span> <span style="color:#080;">$ver</span>  <span style="color:#000;">=</span> <span style="color:#080;">$File::Basename::VERSION</span><span style="color:#000;">;</span>
    <span style="color:#000;">my</span> <span style="color:#080;">$ver2</span> <span style="color:#000;">=</span> <span style="color:#3A3;">File::Basename</span><span style="color:#000;">-&gt;</span><span style="color:#980;">VERSION</span><span style="color:#000;">(</span><span style="color:#000;">)</span><span style="color:#000;">;</span>
    <span style="color:#001;">print</span> <span style="color:#000;">(</span><span style="color:#080;">$ver</span> <span style="color:#000;">==</span> <span style="color:#080;">$ver2</span> <span style="color:#000;">?</span> <span style="color:#00a;">'</span><span style="color:#00a;">ok</span><span style="color:#00a;">'</span> <span style="color:#000;">:</span> <span style="color:#00a;">'</span><span style="color:#00a;">notok</span><span style="color:#00a;">'</span><span style="color:#000;">)</span><span style="color:#000;">;</span>
<span style="color:#000;">}</span>
<span style="color:#000;">my</span> <span style="color:#80f;">%hash</span> <span style="color:#000;">=</span> <span style="color:#f70;">@ARGV</span> <span style="color:#000;">if</span> <span style="color:#f70;">@ARGV</span> <span style="color:#80f;">%</span> <span style="color:#f0f;">2</span> <span style="color:#000;">==</span> <span style="color:#f0f;">0</span><span style="color:#000;">;</span>
<span style="color:#000;">while</span> <span style="color:#000;">(</span><span style="color:#000;">&lt;</span><span style="color:#000;">&gt;</span><span style="color:#000;">)</span> <span style="color:#000;">{</span>
    <span style="color:#300;">print</span> <span style="color:#000;">if</span> <span style="color:#00a;">m/</span><span style="color:#00a;"><span style="color:#800;">\Q</span><span style="color:#080;">$scalar</span><span style="color:#800;">\E</span>|hi</span><span style="color:#00a;">/</span><span style="color:#00a;">i</span><span style="color:#000;">;</span>
<span style="color:#000;">}</span>
<span style="color:#300;">close</span> <span style="color:#f03;">*STDOUT</span><span style="color:#000;">;</span>

