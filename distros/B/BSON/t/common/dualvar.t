use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Scalar::Util 'dualvar';
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

use BSON;

# PERL-737 encoding of dual vars
# should look have an NV representation and be encoded as numbers

ok(my $c = BSON->new, 'got codec object');

my ($number, $str) = (5, 'hello');
my $dualvar = dualvar($number, $str);
ok($dualvar == $number, 'dual var is a number');
is($dualvar, $str, 'dual var is a string');

my $dualvar_bin = $c->encode_one({ dual => $dualvar });
ok(
    $c->decode_one($dualvar_bin)->{'dual'} == $number,
    'round trip for dual var'
);

done_testing;
