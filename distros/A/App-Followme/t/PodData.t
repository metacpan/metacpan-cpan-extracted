#!/usr/bin/env perl
use strict;

use Cwd;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::Requires 'Pod::Simple::XHTML';
use Test::More tests => 10;

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

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;

chdir $test_dir or die $!;
$test_dir = cwd();

#----------------------------------------------------------------------
# Create object

my $obj = App::Followme::PodData->new(extension => 'pm,pod',
                                      title_template => '<h1></h1>',
                                      site_url => 'http://www.example.com/',
                                      package => 'App::Followme::PodData',
                                      pod_directory => $lib,
                                      );
isa_ok($obj, "App::Followme::PodData"); # test 1
can_ok($obj, qw(new build)); # test 2

#----------------------------------------------------------------------
# Test url manipulation

do {
    my $url = "http://www.example.comApp::Followme::PodData";
    my $url_ok =  "poddata.html";
    my $new_url = $obj->alter_url($url);
    is($new_url, $url_ok, "Alter url"); # test 3
};

#----------------------------------------------------------------------
# Test conversion of pod files

do {
    my $pod_directory = $obj->find_pod_directory();
    my $ok_directory = catfile($lib, 'App', 'Followme');
    is($pod_directory, $ok_directory, 'test find pod directory'); # test 4

    my $index_file = $obj->dir_to_filename($pod_directory);
    my $files = $obj->build('files', $index_file);

    my $file_list = join(',', @$files);
    ok(index($file_list, '.pod') > 0, "Build file list"); # test 5

    my @files = sort(@$files);
    my $file = shift(@files);
    my $body = $obj->build('body', $file);

    ok(index($$body, "SYNOPSIS") > 0, "Convert Text"); # test 6

    my $title = $obj->build('$title', $file);
    is($$title, "App::Followme::BaseData", "Get title"); # test 7

    my $summary = $obj->build('$summary', $file);
    ok(index($$summary, "base class") > 0, "Get summary"); # test 8

    my @pod_files = grep(/\.pod$/, @files);
    foreach my $pod_file (@pod_files) {
        my $body = $obj->build('body', $pod_file);
        my @urls = $$body =~ /href="([^"]*)"/g;
        like($urls[0], qr(^[\/a-z]+\.html$), "Test url conversion"); # test 9
        ok(@urls > 10, "Test finding all urls"); # test 10
    }
};
