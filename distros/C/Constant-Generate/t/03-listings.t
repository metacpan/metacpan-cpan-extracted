#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Constant::Generate [qw(
    FOO BAR BAZ
)], -allvalues => 'MYVALS', -allsyms => 'MYSYMS';

my %expected_values = (
    0 => undef,
    1 => undef,
    2 => undef
);

my %expected_syms = (
    'FOO' => undef,
    'BAR' => undef,
    'BAZ' => undef,
);

$expected_values{$_} = $_ for (MYVALS);
$expected_syms{$_} = $_ for (MYSYMS);

ok(!grep(!defined $_, values %expected_values),
   "allvalues");
ok(!grep(!defined $_, values %expected_syms),
   "allsyms");

done_testing();