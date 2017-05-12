#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';

use Log::Log4perl qw( :easy );

use Autocache qw( autocache );

Log::Log4perl->easy_init( $DEBUG );

Autocache->initialise( filename => './fib.conf', logger => get_logger() );

autocache 'fib';

# If you're trying this with the above line commented out then you'll be
# waiting for...some time...

foreach my $i ( 1..100 )
{
    print "fib $i : " . fib( $i ) . "\n";
}

exit;

sub fib
{
    my ($n) = @_;
    return 1 if( $n == 1 || $n == 2 );
    return ( fib( $n - 1 ) + fib( $n - 2 ) );
}
