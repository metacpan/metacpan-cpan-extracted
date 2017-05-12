#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 7;
use Color::Brewer;

my @color_schemes = Color::Brewer::color_schemes( data_nature => 'qualitative', number_of_data_classes => 3 );

cmp_ok( scalar @color_schemes, '>', 0, 'At least 1 color scheme for 3 qualitative' );
is( scalar @{ $color_schemes[0] }, 3, 'Exactly 3 colors for 3 data classes' );
like( scalar $color_schemes[0][0], '/rgb\(\d{1,3},\d{1,3},\d{1,3}\)/', 'Colors have rgb syntax' );

my @empty_color_schemes = Color::Brewer::color_schemes( data_nature => 'divergent', number_of_data_classes => 40 );
is( scalar @empty_color_schemes, 0, 'Returns empty array when there is not color scheme available' );

my @data_nature_not_available = Color::Brewer::color_schemes( data_nature => 'rare', number_of_data_classes => 3 );
is( scalar @data_nature_not_available, 0, 'Returns empty array where is not color scheme available' );

my @rdbu_scheme = Color::Brewer::named_color_scheme( name => 'RdBu', number_of_data_classes => 4 );
cmp_ok( scalar @rdbu_scheme, '>', 0, 'RdBu color scheme exists' );
is( scalar @rdbu_scheme, 4, 'Number of data classes is equal' );
