# Test suite for ControlBreak

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use Test::More tests => 5;
use Test::Exception;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use ControlBreak;
   
my $cb;


$cb = ControlBreak->new( 'L1' );

throws_ok 
    { $cb->test() } 
    qr/[*]E[*] number of arguments to test[(][)] must match those given in new[(][)]/, 
    'test() croaks when number of arguments doesn\'t match new()';

my ($x, $y);
throws_ok 
    { $cb->test( $x, $y ) } 
    qr/[*]E[*] number of arguments to test[(][)] must match those given in new[(][)]/, 
    'test() croaks when number of arguments doesn\'t match new()';

throws_ok
    { $cb->last('123') }
    qr/[*]E[*] invalid level number: 123/,
    'last() croaks when given an invalid level number';

throws_ok
    { $cb->last('XXX') }
    qr/[*]E[*] invalid level name: XXX/,
    'last() croaks when given an invalid level name';


$cb = ControlBreak->new( 'L1_country', 'L2_city', '+L3_areanum' );

throws_ok
    { $cb->comparison( XXX => 'eq' ) }
    qr/[*]E[*] invalid level name: XXX/, 
    'comparison() croaks when given an invalid level name';

