#!/usr/bin/perl -w
use strict;

# Use POEny!
use Acme::POE::Knee;

        
my $pony = new Acme::POE::Knee (
	dist        => 20,
    ponies  => {
        'dngor'     => 5,
        'Abigail'   => 5.2, 
        'Co-Kane'   => 5.4, 
        'MJD'       => 5.6,
        'acme'      => 5.8, 
    },
);

# start the race
$pony->race( );

exit;