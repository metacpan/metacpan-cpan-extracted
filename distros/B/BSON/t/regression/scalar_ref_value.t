use strict;
use warnings;

use Test::More;
use Test::Fatal;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

use BSON;
use boolean;

my $c = BSON->new;

# PERL-489 Providing a reference to a scalar was giving the memory reference not
# the scalar

my $value = 42.2;
$value = "hello";

is(
    exception { $c->encode_one( { value => \$value } ) },
    undef,
    "encoding ref to PVNV is not fatal",
);

done_testing;
