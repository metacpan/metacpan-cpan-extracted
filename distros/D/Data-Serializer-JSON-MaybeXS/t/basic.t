#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use Data::Serializer::Raw;

my $s = Data::Serializer::Raw->new(
    serializer => 'JSON::MaybeXS',
);

my $json = $s->serialize( {foo=>32} );
my $data = $s->deserialize( $json );

is_deeply(
    $data,
    {foo=>32},
    'serialize then deserialize worked',
);

done_testing;
