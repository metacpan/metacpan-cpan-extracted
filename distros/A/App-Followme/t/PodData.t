#!/usr/bin/env perl
use strict;

use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::Requires 'Pod::Simple::XHTML';
use Test::More tests => 12;

use lib '../..';

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::PodData;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir, 0, 1) if -e $test_dir;
mkdir($test_dir) unless -e $test_dir;
 
chdir $test_dir or die $!;

#----------------------------------------------------------------------
# Create object

my %configuration = (top_directory => $test_dir,
                    base_directory => $test_dir,
                    extension => 'pm,pod',
                    title_template => '<h1></h1>',
                    site_url => 'http://www.example.com/',
                    package => 'App::Followme::PodData',
                    pod_directory => $lib,
                   );

my $obj = App::Followme::PodData->new(%configuration);

isa_ok($obj, "App::Followme::PodData"); # test 1
can_ok($obj, qw(new build)); # test 2


#----------------------------------------------------------------------
# Test file handling 
do {
    my @files = $obj->find_matching_files($obj->{base_directory});
    ok(@files > 10, "Find matching files"); # test 3

    my $ok_filename = catfile($test_dir, 'basedata.html');
    my $filename = $obj->convert_filename($files[0]);
    is($filename, $ok_filename, "Get converted file"); # test 4
};

#----------------------------------------------------------------------
# Test url manipulation

do {
    my $url = "App::Followme::PodData";
    my $url_ok =  "poddata.html";
    my $new_url = $obj->alter_url($url);
    is($new_url, $url_ok, "Alter url"); # test 5
};

#----------------------------------------------------------------------
# Test conversion of pod files

do {
    my ($pod_directory, $package_path) = $obj->find_base_directory();
    my $directory = catfile($pod_directory, @$package_path);
    my $ok_directory = catfile($lib, 'App');
    is($directory, $ok_directory, 'test find base directory'); # test 6

    my $index_file = $obj->dir_to_filename($obj->{base_directory});
    my $files = $obj->build('all_files', $index_file);
    ok(@$files > 25, "Build file list"); # test 7

    my @files = sort(@$files);
    my $file = $files[0];
    my $body = $obj->build('body', $file);

    ok(index($$body, "SYNOPSIS") > 0, "Convert Text"); # test 8

    my $title = $obj->build('$title', $file);
    is($$title, "App::Followme::BaseData", "Get title"); # test 9

    my $summary = $obj->build('$summary', $file);
    ok(index($$summary, "base class") > 0, "Get summary"); # test 10

    foreach my $file (@$files) {
        my @dirs = splitdir($file);
        my $basename = pop(@dirs);
        if ($basename eq 'Guide.pm') {
            my $body = $obj->build('body', $file);
            my @urls = $$body =~ /href="([^"]*)"/g;
            like($urls[0], qr(^[\-\/a-z]+\.html$), "Test url conversion"); # test 11
            ok(@urls > 10, "Test finding all urls"); # test 12
        }
    }
};
