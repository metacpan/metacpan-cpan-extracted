#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'CCC'    => {},
    'C-C'    => {},
    'C=C'    => { '=' => 1 },
    'C-1C1'  => {},
    'C=1C1'  => { '=' => 1 },
    'C(=O)'  => { '=' => 1 },
    'C(C=C)' => { '=' => 1 },

    'cc'     => { ':' => 1 },
    'c:c'    => { ':' => 1 },
    'c(c)'   => { ':' => 1 },
    'c1ccc1' => { ':' => 4 },
    'c-c'    => {},
    'c(-c)'  => {},
    'c1cc-1' => { ':' => 2 },
    'c-1cc1' => { ':' => 2 },
);

plan tests => 2 * scalar keys %cases;

for my $case (sort keys %cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @graphs = $parser->parse( $case );

    is( scalar @graphs, 1 );
    my $graph = shift @graphs;

    my %orders;
    for ($graph->edges) {
        next if !$graph->has_edge_attribute( @$_, 'bond' );
        $orders{ $graph->get_edge_attribute( @$_, 'bond' )} ++;
    }

    is( serialize( \%orders ), serialize( $cases{$case} ) );
}

sub serialize
{
    my( $orders ) = @_;
    return join ' ', map { $_ . '(' . $orders->{$_} . ')' }
                         sort keys %$orders;
}
