#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;
use Test2::V0;

use Data::Xslate;
use Storable qw( freeze thaw );

my $xslate = Data::Xslate->new();

my $data = {
    a => 2,
    b => '=a',
};

my $orig_data = thaw( freeze( $data ) );

$xslate->render( $data );

is(
    $data,
    $orig_data,
    'data was not changed',
);

done_testing;
