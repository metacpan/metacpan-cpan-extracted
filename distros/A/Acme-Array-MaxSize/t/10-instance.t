#!/usr/bin/perl
use warnings;
use strict;

use Acme::Array::MaxSize;
use Test::More tests => 19;

tie my @arr, 'Acme::Array::MaxSize', 3;


$#arr = 3;
is($#arr, 2, '$#=');

@arr = (1, 2, 3, 4);
is("@arr", '1 2 3', '=()');

shift @arr;
is("@arr", '2 3', 'shift');

push @arr, 5, 6, 7, 8;
is("@arr", '2 3 5', 'push');

pop @arr;
is("@arr", '2 3', 'pop');

unshift @arr, -1, 0, 1;  # From right!
is("@arr", '1 2 3', 'unshift');

splice @arr, 0, 0, 4, 5;
is "@arr", '1 2 3', 'splice 0 0';

splice @arr, 0, 1, 4, 5;
is "@arr", '5 2 3', 'splice 0 1';

splice @arr, 0, 2, 0, 1, 4;
is "@arr", '1 4 3', 'splice 0 2';

splice @arr, 3, 1, 2;
is "@arr", '1 4 3', 'splice offset >';

splice @arr, 2, 0, 2, 3;
is "@arr", '1 4 3', 'splice 2 0';

splice @arr, 2, 1, 2, 5;
is "@arr", '1 4 2', 'splice 2 1';

splice @arr, 2, 2, 5, 6, 3;
is "@arr", '1 4 5', 'splice 2 2';

splice @arr, 1, 0, 3;
is "@arr", '1 4 5', 'splice 1 0';

splice @arr, 1, 0, 2, 3;
is "@arr", '1 4 5', 'splice 1 0 + list';

splice @arr, 1, 1, 2, 3;
is "@arr", '1 2 5', 'splice 1 1';

splice @arr, 1, 2, 3, 4, 6;
is "@arr", '1 3 4', 'splice 1 2';

@arr = (1, 2);
splice @arr, 1, 0, 3;
is "@arr", '1 3 2', 'prolong';

@arr = (1, 2);
splice @arr, 1, 0, 3, 4;
is "@arr", '1 3 2', 'prolong >';
