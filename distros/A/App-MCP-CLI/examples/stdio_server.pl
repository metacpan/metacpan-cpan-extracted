#!/usr/bin/env perl

use strict;
use warnings;

use utf8;
use MCP::Server;
use experimental 'signatures';

my $server = MCP::Server->new;

$server->tool(
    name        => 'add_numbers',
    description => 'Adds two numeric values together and returns the sum.',

    input_schema => {
        type       => 'object',
        properties => {
            a => { type => 'number', description => 'The first number'  },
            b => { type => 'number', description => 'The second number' },
        },
        required => ['a', 'b'],
    },

    code => sub ($tool, $args) {
        my $num1 = $args->{a};
        my $num2 = $args->{b};
        my $sum  = $num1 + $num2;

        return "The result of adding $num1 and $num2 is $sum.";
    }
);

$server->to_stdio;
