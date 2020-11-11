#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
use JSON;

use Test::More tests => 13;

use Chart::Plotly::Plot;
use Chart::Plotly::Trace::Scatter;

sub GeneratePlotAndComparePlotAndJSON {
    my $json = shift;

    my $plot = Chart::Plotly::Plot->from_json($json);

    my $perl_hash_from_json = from_json($json);

    is_deeply( $perl_hash_from_json->{"data"},   $plot->traces );
    is_deeply( $perl_hash_from_json->{"layout"}, $plot->layout );
    is_deeply( $perl_hash_from_json->{"config"}, $plot->config );

    is_deeply( $perl_hash_from_json, $plot->TO_JSON );    # comparing perl objects to avoid the whitespace management
}

{
    my $simple_json = <<'ENDOFJSON';
{
    "data": [{
         "type": "scatter",
         "x": [1, 2, 3],
         "y": [1, 2, 3]
        }],
    "layout": {

        },
    "config": {

        }
}
ENDOFJSON

    GeneratePlotAndComparePlotAndJSON($simple_json);
}

{
    my $json_without_config = <<'ENDOFJSON';
{
    "data": [{
         "type": "scatter",
         "x": [1, 2, 3],
         "y": [1, 2, 3]
        }],
    "layout": {
        "title": {
                "text": "sample title"
            }
        }
}
ENDOFJSON

    GeneratePlotAndComparePlotAndJSON($json_without_config);
}

{
    my $json_without_layout = <<'ENDOFJSON';
{
    "data": [{
         "type": "scatter",
         "x": [1, 2, 3],
         "y": [1, 2, 3]
        }],
    "config": {
         "responsive": true  
        }
}
ENDOFJSON

    GeneratePlotAndComparePlotAndJSON($json_without_layout);
}

SKIP: {
    eval {
        require PDL;
        PDL->import;
    };
    if ($@) {
        skip( "Have not PDL", 1 );
    }

    my $plot = Chart::Plotly::Plot->new(
                 traces => [ Chart::Plotly::Trace::Scatter->new( x => pdl( [ 0, 1, 2 ] ), y => pdl( [ 0, 1, 2 ] ) ) ] );

    my $expected_json = { data => [ { type => 'scatter', x => [ 0, 1, 2 ], y => [ 0, 1, 2 ] } ] };

    my $json = JSON->new()->allow_blessed(1)->convert_blessed(1);

    is_deeply( $expected_json, $json->decode( $plot->to_json_text ) );
}
