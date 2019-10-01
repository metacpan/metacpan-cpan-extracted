#!/usr/bin/env perl6

my @court = (
	[ 'FIN' ],
	[ 9 ,10 ],
	[   8   ],
	[ 6 , 7 ],
	[   5   ],
	[   4   ],
	[ 2 , 3 ],
	[   1   ],
);

my $skip = @court.[1..*].pick.pick;
my @play;

for @court.reverse -> $hop {
	@play.push( $hop.map( *.subst( /^$skip$/,'🚫' ).list ) );
}

say @play.reverse.join( "\n" );
