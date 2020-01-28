# make;perl -Iblib/lib t/46_x2y_numeric_base_converts.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 12;

is( dec2bin(101), '1100101', 'dec2bin');
is( dec2hex(101), '65',      'dec2hex');
is( dec2oct(101), '145',     'dec2oct');
is( bin2dec(1010011110), '670',  'bin2dec');
is( bin2hex(1010011110), '29e',  'bin2hex');
is( bin2oct(1010011110), '1236', 'bin2oct');
is( hex2dec(101),        '257',  'hex2dec');
is( hex2bin(101),        '100000001', 'hex2bin');
is( hex2oct(101),        '401',       'hex2oct');
is( oct2dec(101), '65', 'oct2dec');
is( oct2bin(101), '1000001', 'oct2bin');
is( oct2hex(101), '41', 'oct2hex');
