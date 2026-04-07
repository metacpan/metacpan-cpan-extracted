#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;
use Data::Dumper;

use_ok('Convert::VLQ');
Convert::VLQ->import( qw( encode_vlq decode_vlq ) );

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

my @tests = ( [0,'A'], [1024,'ggC'], [1,'C'], [-1,'D'], [123,'2H'], [123456789,'qxmvrH'],
              [0x1040,'gkI'], [0x1f1d,'6xP'],
              [[0,0,0,0],'AAAA'], [[-1,-1,-1,-1 ], 'DDDD'], [[123,456,789], '2HwcqxB'] );

foreach my $pair ( @tests ) {
    my $a = encode_vlq( $pair->[0] );
    is( $a, $pair->[1], "encode_vlq(".Dumper( $pair->[0] ).") = ".Dumper($a) );
}

foreach my $pair ( @tests ) {
    my $a = decode_vlq( $pair->[1] );
    my $want = $pair->[0];
    $want = [$want] unless ref $want;
    is_deeply( $a, $want, "decode_vlq(".Dumper( $pair->[1] ).") = ".Dumper($a) );
}


