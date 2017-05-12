#!perl -T

use Test;
use strict;
use utf8;
$^W=0;

plan(tests => 17);


# Test 1: See if the module loads

eval 'use Convert::Number::Greek  "num2greek"';
ok($@ eq '');


# Test 2: Lowercase

ok( num2greek(5694) eq '͵εχϟδʹ' );

# Tests 3 & 4: Uppercase 

ok( num2greek(2485, {upper => 1}) eq '͵ΒΥΠΕʹ' );
ok( num2greek(6825, {uc    => 1}) eq '͵ϚΩΚΕʹ' );

# Δοκιμασίες εʹ ὡς ιʹ: Stigma vs. sigma & tau

ok( num2greek(1866) eq '͵αωξϛʹ' );
ok( num2greek(2576, {stigma => 0}) eq '͵βφοστʹ' );
ok( num2greek(8156, {uc     => 1}) eq '͵ΗΡΝϚʹ' );
ok( num2greek(  76, {upper  => 1}) eq 'ΟϚʹ' );
ok( num2greek(4476, {stigma => 0, upper  => 1}) eq '͵ΔΥΟΣΤʹ' );
ok( num2greek(7306, {stigma => 0, uc     => 1}) eq '͵ΖΤΣΤʹ' );

# Tests 11-16: Koppa

ok( num2greek(7795) eq '͵ζψϟεʹ' );
ok( num2greek(3296, {arch_koppa => 1}) eq '͵γσϙϛʹ' );
ok( num2greek(3794, {uc         => 1}) eq '͵ΓΨϞΔʹ' );
ok( num2greek(5296, {upper      => 1}) eq '͵ΕΣϞϚʹ' );
ok( num2greek(5998, {arch_koppa => 1, upper  => 1}) eq '͵ΕϠϘΗʹ' );
ok( num2greek(1790, {arch_koppa => 1, uc     => 1}) eq '͵ΑΨϘʹ' );

# Test 17: No number sign

ok( num2greek(1295, {'numbersign'}) eq '͵ασϟε' );
