#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 5;
use Test::Differences;

use File::Slurp 'write_file';
use File::Spec;

use FindBin qw($Bin);
use lib "$Bin/lib";

our $BASE_PATH = File::Spec->catfile($Bin, 'output');

BEGIN {
    use_ok ( 'Chart::OFC2' )          or exit;
    use_ok ( 'Chart::OFC2::Scatter' ) or exit;
}

exit main();

sub main {
    my $chart = Chart::OFC2->new(
        'title'  => 'Scatter chart test',
    );
    
    my $scatter = Chart::OFC2::Scatter->new(
        'values' => [
            { "x" => -5,  "y" => -5 },
            { "x" => 0,   "y" => 0 },
            { "x" => 5,   "y" => 5, "dot-size" => 20 },
            { "x" => 5,   "y" => -5, "dot-size" => 5 },
            { "x" => -5,  "y" => 5, "dot-size" => 5 },
            { "x" => 0.5, "y" => 1, "dot-size" => 15 }
        ],
        'colour' => '#40FF0D',
    );
    $chart->add_element($scatter);

    eq_or_diff(
        $scatter->TO_JSON,
        {
            'colour' => '#40FF0D',
            'type'   => 'scatter',
            'values' => [
                { "x" => -5,  "y" => -5 },
                { "x" => 0,   "y" => 0 },
                { "x" => 5,   "y" => 5, "dot-size" => 20 },
                { "x" => 5,   "y" => -5, "dot-size" => 5 },
                { "x" => -5,  "y" => 5, "dot-size" => 5 },
                { "x" => 0.5, "y" => 1, "dot-size" => 15 }
            ],
        },
        'scatter element TO_JSON'
    );

    my $chart_data = $chart->render_chart_data();
    ok($chart_data, 'generate scatter chart data');
    
    # write output to file
    my $output_filename = File::Spec->catfile($BASE_PATH, 'scatter-data.json');
    ok(write_file($output_filename, $chart_data), 'saving scatter-chart JSON to "'.$output_filename.'"');
    
    return 0;
}
