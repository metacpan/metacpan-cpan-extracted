# Test suite for ControlBreak

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use Test::More tests => 7;
use Test::Exception;

use FindBin;
use lib $FindBin::Bin . '/../lib';

require_ok 'ControlBreak';

my $cb = new_ok 'ControlBreak' => [ 'L1_country', 'L2_city', '+L3_areanum' ];

can_ok $cb, qw(
    iteration
    level_names
    break
    comparison
    continue
    last
    levelname
    levelnum
    level_numbers
    reset
    test
    test_and_do
);

throws_ok
    { ControlBreak->new }
    qr/[*]E[*] at least one argument is required/,
    'new() croaks with no arguments';

throws_ok
    { ControlBreak->new( '123x' ) }
    qr/[*]E[*] invalid level name/,
    'new() croaks with invalid level name';

throws_ok
    { ControlBreak->new( qw( L1 L2 L3 L1 ) ) }
    qr/[*]E[*] duplicate level name: L1/,
    'new() croaks wth duplicate level name';

throws_ok
    { $cb->comparison( XXX => 'eq' ) }
    qr/[*]E[*] invalid level name: XXX/,
    'comparison() croaks wth invalid level name';


