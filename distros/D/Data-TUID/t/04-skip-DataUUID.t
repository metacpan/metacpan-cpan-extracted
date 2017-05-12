#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

BEGIN {
    %Data::TUID::BestUUID::skip = ( DataUUID => 1 );
}

use Data::TUID;

plan skip_all => 'No UUID package available' unless %Data::TUID::BestUUID::loaded;

plan qw/ no_plan /;

my ( $result );

$result = Data::TUID::BestUUID->new_uuid;
is( length( $result ), 36 );
