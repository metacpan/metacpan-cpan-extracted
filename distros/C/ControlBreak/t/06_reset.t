# Test suite for ControlBreak

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use Test::More tests => 3;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use ControlBreak;
   
my $cb = ControlBreak->new( 'City' );

my @got_1;
my @got_2;

note "Testing two passes over the same data with a reset in between";


foreach my $x ( qw( Ottawa Toronto Hamilton Hamilton Hamilton Vancouver ) ) {
    $cb->test( $x );
    push @got_1, $cb->levelnum;
    $cb->continue;
}

$cb->reset;

ok $cb->iteration == 0, 'iteration reset';

foreach my $x ( qw( Ottawa Toronto Hamilton Hamilton Hamilton Vancouver ) ) {
    $cb->test( $x );
    push @got_2, $cb->levelnum;
    $cb->continue;
}

is_deeply \@got_1, \@got_2, 'second pass (following reset)';


note "Testing two passes over the same data without a reset in between";

# create a new object for this second test
$cb = ControlBreak->new( 'City' );

@got_1 = ();
@got_2 = ();

foreach my $x ( qw( Ottawa Toronto Hamilton Hamilton Hamilton Vancouver ) ) {
    $cb->test( $x );
    push @got_1, $cb->levelnum;
    $cb->continue;
}

# no reset called -- so the next pass should fail

foreach my $x ( qw( Ottawa Toronto Hamilton Hamilton Hamilton Vancouver ) ) {
    $cb->test( $x );
    push @got_2, $cb->levelnum;
    $cb->continue;
}

ok $got_1[0] != $got_2[0], 'second pass (without reset) failed as expected';

