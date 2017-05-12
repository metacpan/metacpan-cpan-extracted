use strict;
use Date::Korean;
use Test::More tests => 36;

use utf8;

my @tests = (
    { solar=>[1391, 2, 5], lunisolar=>[1391, 1, 1, 0], ganzi=>[qw/辛未 庚寅 己丑/] },
    { solar=>[2050,12,31], lunisolar=>[2050,11,18, 0], ganzi=>[qw/庚午 戊子 乙酉/] },
    { solar=>[1582,10, 4], lunisolar=>[1582, 9,18, 0], ganzi=>[qw/壬午 庚戌 癸酉/] },
    { solar=>[1582,10,15], lunisolar=>[1582, 9,19, 0], ganzi=>[qw/壬午 庚戌 甲戌/] },
    { solar=>[1393, 1,12], lunisolar=>[1392,12,30, 0], ganzi=>[qw/壬申 癸丑 丙子/] },
    { solar=>[1393, 1,13], lunisolar=>[1392,12, 1, 1], ganzi=>[qw/壬申 癸丑 丁丑/] },
    { solar=>[1393, 2,11], lunisolar=>[1392,12,30, 1], ganzi=>[qw/壬申 癸丑 丙午/] },
    { solar=>[1393, 2,12], lunisolar=>[1393, 1, 1, 0], ganzi=>[qw/癸酉 甲寅 丁未/] },
    { solar=>[1890, 3,20], lunisolar=>[1890, 2,30, 0], ganzi=>[qw/庚寅 己卯 庚子/] },
    { solar=>[1890, 3,21], lunisolar=>[1890, 2, 1, 1], ganzi=>[qw/庚寅 己卯 辛丑/] },
    { solar=>[1890, 4,18], lunisolar=>[1890, 2,29, 1], ganzi=>[qw/庚寅 己卯 己巳/] },
    { solar=>[1890, 4,19], lunisolar=>[1890, 3, 1, 0], ganzi=>[qw/庚寅 庚辰 庚午/] },
);

for my $test (@tests) {
    is(join('',@{$test->{lunisolar}}), join('',sol2lun(@{$test->{solar}})) );
    is(join('',lun2sol(@{$test->{lunisolar}})), join('',@{$test->{solar}}) );
    is(join('',get_ganzi(@{$test->{lunisolar}})), join('',@{$test->{ganzi}}) );
}
