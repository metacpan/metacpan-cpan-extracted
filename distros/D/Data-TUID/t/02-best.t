#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Data::TUID::BestUUID;

my ( $uuid, $canonical_uuid, $result, %have );

$have{ DataUUID } = eval { require Data::UUID };
$have{ LibUUID } = eval { require Data::UUID::LibUUID };

$uuid = 'e3f590ee-ecc3-4a1e-a37f-863951f10aaf';

$canonical_uuid = Data::TUID::BestUUID->uuid_to_canonical( $uuid );
is( length( $canonical_uuid ), 36 );

$result = Data::TUID::BestUUID->new_uuid;
is( length( $result ), 36 );

if ( $have{LibUUID} ) {
}

if ( $have{DataUUID} ) {
    # No LibUUID
    local %Data::TUID::BestUUID::loaded = ( DataUUID => 1 );
    $result = Data::TUID::BestUUID->uuid_to_canonical( $uuid );

    is( $canonical_uuid, $result );

    $result = Data::TUID::BestUUID->uuid_to_canonical( $canonical_uuid );
    is( $canonical_uuid, $result );
    is( length $result, 36 );
}

