#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;
use English;

use Dash;
use aliased 'Dash::Table::DataTable';

my @columns = qw(a b c d);
my $data = [
    map {
        {
            map {$ARG => rand(100)} @columns
        }
    } 1 .. 5
];

my $app = Dash->new(app_name => 'Dash Table Sample');

$app->layout(DataTable->new(
    id=>'table',
    columns=> [map {{name => $ARG, id => $ARG}} @columns],
    data=> $data,
));

$app->run_server()

