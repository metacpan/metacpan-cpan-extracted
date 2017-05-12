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
    use_ok ( 'Chart::OFC2' )       or exit;
    use_ok ( 'Chart::OFC2::Line' ) or exit;
}

exit main();

sub main {
    my $chart = Chart::OFC2->new(
        'title'  => 'Line chart test',
        'x_axis' => Chart::OFC2::XAxis->new(
            labels => [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun' ],
            is3d   => 1,
        ),
        'y_axis' => Chart::OFC2::YAxis->new(
            'min'    => 'a',
            'max'    => 'a',
        ),
    );
    
    my $line = Chart::OFC2::Line->new(
        'values' => [ map { 12 - $_ } 0..5 ],
        'colour' => '#40FF0D',
    );
    $chart->add_element($line);

    eq_or_diff(
        $line->TO_JSON,
        {
            'colour' => '#40FF0D',
            'type'   => 'line',
            'values' => [ 12,11,10,9,8,7 ],
        },
        'line element TO_JSON'
    );

    my $line2 = Chart::OFC2::Line::Dot->new(
        'colour'   => '#186000',
        'dot-size' => 3,
    );
    $line2->values([ 10..15 ]);
    $chart->add_element($line2);
    
    my $chart_data = $chart->render_chart_data();
    ok($chart_data, 'generate bar chart data');
    
    # write output to file
    my $output_filename = File::Spec->catfile($BASE_PATH, 'line-data.json');
    ok(write_file($output_filename, $chart_data), 'saving line-chart JSON to "'.$output_filename.'"');
    
    return 0;
}
