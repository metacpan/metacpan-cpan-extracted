#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';

use Log::Log4perl qw( :easy );

use Autocache qw( autocache );

Log::Log4perl->easy_init( $DEBUG );

use Devel::Size qw( total_size );

Autocache->initialise( filename => './lru.conf', logger => get_logger() );

autocache 'generate_data';

foreach my $i ( 1..2 )
{
    foreach my $n ( 1..10 )
    {
        my $junk = generate_data( $n );
        get_logger()->info( "n: $n - square: " . $junk->{square} );
    }
}

#foreach my $n ( 30..40 )
#{
#    my $junk = generate_data( $n );
#    get_logger()->info( "n: $n - square: " . $junk->{square} );
#}

my $strategy = Autocache->singleton->get_strategy( 'stat' );

my $stats = $strategy->statistics;

get_logger()->info( "create count: " . $stats->{create} );
get_logger()->info( "hit count: " . $stats->{hit} );
get_logger()->info( "miss count: " . $stats->{miss} );
get_logger()->info( "total count: " . ( $stats->{hit} + $stats->{miss} ) );


exit;

sub generate_data
{
    my ($n) = @_;
    my $val = {
        key => $n * 42,
        square => $n * $n,
        root => sqrt( $n ),
    };
    get_logger()->info( "data size: " . total_size( $val ) );
    return $val;
}
