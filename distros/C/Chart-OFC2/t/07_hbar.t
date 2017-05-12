#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 5;
use Test::Differences;

use File::Slurp 'write_file';
use File::Spec;

use FindBin qw($Bin);
use lib "$Bin/lib";

our $BASE_PATH = File::Spec->catfile($Bin, 'output');

BEGIN {
    use_ok ( 'Chart::OFC2' )      or exit;
    use_ok ( 'Chart::OFC2::HBar' ) or exit;
}

exit main();

sub main {
    my $chart = Chart::OFC2->new(
        'title'  => 'HBar chart test',
        'y_axis' => Chart::OFC2::YAxis->new(
            labels => { 
                labels => [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun' ]
            },
            'offset' => 1,
        ),
        'tooltip' => {
            'mouse' => 2,
        },
    );
    
    my $hbar = Chart::OFC2::HBar->new(
        'values' => [ { 'left' => 1.5, 'right' => 3, }, (1..5), ],
        'colour' => '#40FF0D',
    );

    eq_or_diff(
        $hbar->TO_JSON,
        {
          'colour' => '#40FF0D',
          'type' => 'hbar',
          'values' => bless( {
               'values' => [
                     { 'left' => 1.5, 'right' => 3 },
                     { 'right' => 1 },
                     { 'right' => 2 },
                     { 'right' => 3 },
                     { 'right' => 4 },
                     { 'right' => 5 },
               ]
             }, 'Chart::OFC2::HBarValues' )
        },
        'hbar element TO_JSON'
    );
    
    $chart->add_element($hbar);
    my $chart_data = $chart->render_chart_data();
    ok($chart_data, 'generate bar chart data');
    
    # write output to file
    my $output_filename = File::Spec->catfile($BASE_PATH, 'hbar-data.json');
    ok(write_file($output_filename, $chart_data), 'saving hbar-chart JSON to "'.$output_filename.'"');
    
    return 0;
}
