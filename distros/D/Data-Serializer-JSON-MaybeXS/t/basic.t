#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;

use Data::Serializer::Raw;

my $s = Data::Serializer::Raw->new(
    serializer => 'JSON::MaybeXS',
);

my $json = $s->serialize( {foo=>32} );
my $data = $s->deserialize( $json );

is(
    $data,
    {foo=>32},
    'serialize then deserialize worked',
);

done_testing;
