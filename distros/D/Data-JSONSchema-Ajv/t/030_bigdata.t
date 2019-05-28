#!perl

use strict;
use warnings;
use utf8;

use Test::More;
use FindBin '$Bin';
use Data::JSONSchema::Ajv;

my $bigdata = do "$Bin/bigdata.pl" or die $!;
my $copy = [@$bigdata];

my $ajv = Data::JSONSchema::Ajv->new();
my $validator = $ajv->make_validator({
    type => 'array',
    items => {
        type => 'object',
        properties => {
            rectype   => { type => 'string', minLength => 1 },
            subdomain => { type => 'string', minLength => 1 },
            data      => { type => 'string', pattern => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' }
        }
    },
    minItems => 400_000,
    maxItems => 400_000,
});

my $errors = $validator->validate(\$bigdata);

ok $errors, 'has errors';
is_deeply $bigdata, $copy, 'got same data after validation';

done_testing();
