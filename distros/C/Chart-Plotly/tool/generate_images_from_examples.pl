#!/usr/bin/env perl 
use strict;
use warnings;
use utf8;

use Selenium::Firefox;
use Path::Tiny;

my $driver = Selenium::Firefox->new( marionette_enabled => 1, firefox_binary => "/opt/firefox/firefox-bin" );

$driver->set_window_size(520, 480);
my $samples_folder = path('examples/traces');
for my $trace_example ($samples_folder->children(qr/\.pl$/)) {
    print "Trace file $trace_example\n";
    
    my $trace_name = $trace_example->basename;
    $trace_name =~ s/\.pl$//;
    
    system('perl -Ilib ' . $trace_example);
    
    my $tmp_path = path('/tmp');
    my @candidate_files = sort {(stat($b))[9] <=> (stat($a))[9]} $tmp_path->children(qr/\.html$/);
    print $candidate_files[0], "\n";
    
    $driver->get('file://' . $candidate_files[0]);
    my $image_name = $trace_name . ".png";
    $driver->capture_screenshot($samples_folder->child($image_name) . "");

    my $html_trace_file = $samples_folder->child($trace_name . ".html");
    $candidate_files[0]->copy($html_trace_file);
}

$driver->quit;

system('montage ' . $samples_folder . '/*.png examples/montage_all_traces.png');

