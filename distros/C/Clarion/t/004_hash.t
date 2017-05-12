# -*- perl -*-

# t/004_hash.t - fetching record as hash. Random access

use strict;
use Test::More tests => 2;
use Clarion;

my $z=new Clarion "dat/adv1.dat";

is_deeply($z->get_record_hash(3),
    {ID => 3, B => 3, D1 => "-3.03", D2 => "303.03", G => "\x80\3\3\0\0\0\3\3\3",
    M => "Third record", R => "3.03", S => 303, T => "Three", _DELETED => 0},
    'Reading data+memo');

is_deeply($z->get_record_hash(4),
    {ID => 4, B => 4, D1 => "-4.04", D2 => "-404.04", G => "\x80\4\4\x80\0\0\4\4\4",
    M => undef, R => "4.04", S => 404, T => "Four", _DELETED => 0},
    'Reading data-memo');

__END__
