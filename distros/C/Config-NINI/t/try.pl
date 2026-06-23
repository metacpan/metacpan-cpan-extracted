#!/usr/bin/perl
use strict;
use lib '../lib';
use Config::NINI;
use Data::Dumper;

my $ar;
my $nr;

my $dl = [];

$ar = nini_load_file( 'relay.nini', { DIRS => [ '.' ], DL => $dl } );
print Dumper( $ar );

for( 1..1 )
{
#print Dumper( $ar );
  $nr = nini_parse_data( $ar, { DL => $dl, DEBUG => 1 } );
}

print Dumper( $nr );

exit;



my $nini = nini_load( 'relay.nini', ORDERED => 1, MAIN => '*' );

print Dumper( $nini );
