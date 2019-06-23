#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
use JSON;

use Test::More tests => 12;

use Chart::Plotly::Plot;

sub GeneratePlotAndComparePlotAndJSON {
    my $json = shift;

    my $plot = Chart::Plotly::Plot->from_json($json);

    my $perl_hash_from_json = from_json($json);

    is_deeply( $perl_hash_from_json->{"data"},   $plot->traces );
    is_deeply( $perl_hash_from_json->{"layout"}, $plot->layout );
    is_deeply( $perl_hash_from_json->{"config"}, $plot->config );

    is_deeply( $perl_hash_from_json, from_json( $plot->TO_JSON ) )
      ;    # comparing perl objects to avoid the whitespace management
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
