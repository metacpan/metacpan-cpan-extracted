# Test suite for ControlBreak

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use Test::More tests => 26;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use ControlBreak;
   
my $cb = ControlBreak->new( 'L1_alpha' );

note "Testing one-level control break using string comparison";

my @expected =  qw( 0      1       1        0        0        1         );   
foreach my $x ( qw( Ottawa Toronto Hamilton Hamilton Hamilton Vancouver ) ) {
    $cb->test( $x );
    my $expected = shift @expected;
    ok $cb->levelnum == $expected, $expected ? "break on $x" : "no break on $x";
    $cb->continue;
}

note "Testing one-level control break using numeric comparison";

$cb = ControlBreak->new( '+L1_numeric' );

@expected =     qw( 0 1 0 1 1 1 0 0 0  1 );
foreach my $x ( qw( 1 3 3 4 6 7 7 7 7 11 ) ) {
    $cb->test( $x );
    my $expected = shift @expected;
    ok $cb->levelnum == $expected, $expected ? "break on $x" : "no break on $x";
    $cb->continue;
}

note "Testing custom comparison subroutine (strings coerced to numbers)";

# compare routine that coerces strings to numbers
$cb = ControlBreak->new( 'L1' );
$cb->comparison( L1 => sub { ($_[0] + 0) == ($_[1] + 0) } );

@expected =     qw( 0 1 0 1 1 1 0  0 0  1 );
foreach my $x ( qw( 1 3 3 4 6 7 7 07 7 11 ) ) {
    $cb->test( $x );
    my $expected = shift @expected;
    ok $cb->levelnum == $expected, $expected ? "break on $x" : "no break on $x";
    $cb->continue;
}


