use strict;
use warnings;

use Test::More;
use Test::Fatal;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;
use TestTie;

use BSON;

# PERL-737 encoding of simple tied var

ok(my $c = BSON->new, 'got codec object');

my ($number, $str) = (5, 'hello');

my $var;
tie $var, 'TestTie::Scalar';

$var = $number;
my $varnum_bin = $c->encode_one({ mytied => $var });
ok(
    $c->decode_one($varnum_bin)->{'mytied'} == $number,
    'round trip for tie var'
);

$var = $str;
my $varstr_bin = $c->encode_one({ mytied => $var });
is(
    $c->decode_one($varstr_bin)->{'mytied'}, $str,
    'round trip for tie var'
);

done_testing;
