#!/usr/bin/env perl

use Data::Tabulate;
use Test::More;

use File::Basename;
use lib dirname(__FILE__);

my @array     = (1..10);
my $tabulator = Data::Tabulate->new();

$tabulator->do_func('Test', 'remove_var1', 1 );

is_deeply $tabulator->{method_calls}, {
    'Test' => [
        [ 'remove_var1', [ 1 ] ],
    ],
};

my $dump = $tabulator->render('Test',{data => [@array]});

my $check = q~[
  [
    1,
    2,
    3
  ],
  [
    4,
    5,
    6
  ],
  [
    7,
    8,
    9
  ],
  [
    10,
    undef,
    undef
  ]
];
~;

is($dump,$check);

$tabulator->reset_func('Test');

is_deeply $tabulator->{method_calls}, {};

done_testing();
