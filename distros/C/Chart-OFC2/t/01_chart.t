#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 8;

use File::Slurp 'write_file', 'read_file';

use FindBin qw($Bin);
use lib "$Bin/lib";


our $BASE_PATH = File::Spec->catfile($Bin, 'output');

BEGIN {
    use_ok ( 'Chart::OFC2' ) or exit;
}

exit main();

sub main {
    my $chart = Chart::OFC2->new();
    isa_ok($chart, 'Chart::OFC2');
    
    $chart = Chart::OFC2->new(
        'title' => 'test',
    );
    is($chart->title->text, 'test', 'title name coercion');
    
    my @charts = (
        { 'title' => 'Bar test',     'id' => 'bar', },
        { 'title' => 'Pie test',     'id' => 'pie', },
        { 'title' => 'HBar test',    'id' => 'hbar', },
        { 'title' => 'Line test',    'id' => 'line', },
        { 'title' => 'Scatter test', 'id' => 'scatter', },
    );
    
    foreach my $chart (@charts) {
        write_html(%$chart);
    }
    
    return 0;
}

sub write_html {
    my %args = @_;
    
    my $id    = $args{'id'};
    my $title = $args{'title'};
    
    my $chart = Chart::OFC2->new(
        'title' => $title,
    );

    my $html = read_file(File::Spec->catfile($BASE_PATH, '_header.html'));
    $html .= '<h1>'.$title.'</h1>';
    $html .= $chart->render_swf(600, 400, $id.'-data.json?'.time(), $id.'-chart');    # time() to avoid caching
    $html .= read_file(File::Spec->catfile($BASE_PATH, '_footer.html'));
    
    my $output_filename = File::Spec->catfile($BASE_PATH, $id.'.html');
    ok(write_file($output_filename, $html), 'saving "'.$title.'" HTML to "'.$output_filename.'"');
    
    return;
}
