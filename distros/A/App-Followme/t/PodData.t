#!/usr/bin/env perl
use strict;

use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::Requires 'Pod::Simple::XHTML';
use Test::More tests => 7;

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
mkdir $test_dir;
chmod 0755, $test_dir;
chdir $test_dir;

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
# Test conversion of pod files

do {
    my $pod_directory = $obj->find_pod_directory();
    my $ok_directory = catfile($lib, 'App', 'Followme');
    is($pod_directory, $ok_directory, 'test find pod directory'); # test 3

    my $index_file = $obj->dir_to_filename($pod_directory);
    my $files = $obj->build('files', $index_file);

    my $file_list = join(',', @$files);
    ok(index($file_list, '.pod') > 0, "Build file list"); # test 4

    my @files = sort(@$files);
    my $file = shift(@files);
    my $body = $obj->build('body', $file);

    ok(index($$body, "SYNOPSIS") > 0, "Convert Text"); # test 5

    my $title = $obj->build('$title', $file);
    is($$title, "App::Followme::BaseData", "Get title"); # test 6

    my $description = $obj->build('$description', $file);
    ok(index($$description, "base class") > 0, "Get description"); # test 7
};
