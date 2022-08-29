# Test suite for ControlBreak

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use Test::More tests => 4;
use Test::Exception;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use ControlBreak;
   
my $cb = ControlBreak->new( 'L1' );

note "Testing that test() fails if not followed by continue()";

$cb->test('A');
ok $cb->last('L1') eq 'A';
$cb->continue();

$cb->test('B');
ok $cb->last('L1') eq 'A';
$cb->continue();

$cb->test('C');
ok $cb->last('L1') eq 'B';

throws_ok
    { $cb->test('D') }
    qr/[*]E[*] continue[(][)] must be called after test[(][)]/,
    'calling test without continue fails as expected';


