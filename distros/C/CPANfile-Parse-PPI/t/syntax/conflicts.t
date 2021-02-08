#!/usr/bin/perl

use strict;
use warnings;

use CPANfile::Parse::PPI;
use Test::More;
use Data::Dumper;

my $cpanfile = do { local $/; <DATA> };
my $parser   = CPANfile::Parse::PPI->new( \$cpanfile );

is_deeply $parser->modules, [
    {
        'stage' => '',
        'type' => 'conflicts',
        'version' => '0.26',
        'name' => 'Path::Class',
    },
];


done_testing();


__DATA__
conflicts 'Path::Class', 0.26;
 
