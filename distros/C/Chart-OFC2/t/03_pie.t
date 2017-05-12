#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 4;
use File::Slurp 'write_file';
use File::Spec;
use Test::Differences;

use FindBin qw($Bin);
use lib "$Bin/lib";

our $BASE_PATH = File::Spec->catfile($Bin, 'output');

BEGIN {
    use_ok ( 'Chart::OFC2' )      or exit;
    use_ok ( 'Chart::OFC2::Pie' ) or exit;
}

exit main();

sub main {
    my $chart = Chart::OFC2->new(
        title        => 'Pie Chart',
    );
    
    my $pie = Chart::OFC2::Pie->new(
        tip          => '#val# of #total#<br>#percent# of 100%',
    );
    $pie->values([ (1 .. 5) ]);
    $pie->values->labels([qw( IE Firefox Opera Wii Other)]);
    $pie->values->colours([ '#d01f3c', '#356aa0', '#C79810', '#73880A', '#D15600' ]);

    eq_or_diff(
        $pie->TO_JSON(),
        {
            'tip' => '#val# of #total#<br>#percent# of 100%',
            'colours' => [
                '#d01f3c',
                '#356aa0',
                '#C79810',
                '#73880A',
                '#D15600'
            ],
            'type' => 'pie',
            'values' => bless( {
               'colours' => [
                  '#d01f3c',
                  '#356aa0',
                  '#C79810',
                  '#73880A',
                  '#D15600'
                ],
               'values' => [
                 1,
                 2,
                 3,
                 4,
                 5
               ],
               'labels' => [
                 'IE',
                 'Firefox',
                 'Opera',
                 'Wii',
                 'Other'
               ]
             }, 'Chart::OFC2::PieValues' )
        },
        'check default colour set if one is missing',
    );

    my $pie2 = Chart::OFC2::Pie->new(
        values       => [
            { 'value' => 1, 'label' => 'IE', 'colour' => '#d01f3c' },
            { 'value' => 2, 'label' => 'Firefox', 'colour' => '#356aa0' },
            { 'value' => 3, 'label' => 'Opera', 'colour' => '#C79810' },
            4,
            { 'value' => 5, 'label' => 'Other', 'colour' => '#D15600' },
        ],
    );
    
    eq_or_diff(
        $pie2->TO_JSON->{'colours'},
        [
            '#d01f3c',
            '#356aa0',
            '#C79810',
            '#aaaaaa',
            '#D15600'
        ],
        'check color added if one missing',
    );

    my $pie3 = Chart::OFC2::Pie->new(
        values       => [
            { 'value' => 1, 'label' => 'IE', },
            { 'value' => 2, 'label' => 'Firefox', },
        ],
    );
    ok((not exists $pie3->TO_JSON->{'colours'}), 'no color definition if none color set');
    
    
    # create chart data
    $chart->add_element($pie);

    my $chart_data = $chart->render_chart_data();
    ok($chart_data, 'generate pie chart data');
    
    # write output to file
    my $output_filename = File::Spec->catfile($BASE_PATH, 'pie-data.json');
    ok(write_file($output_filename, $chart_data), 'saving pie-chart JSON to "'.$output_filename.'"');
    
    return 0;
}
