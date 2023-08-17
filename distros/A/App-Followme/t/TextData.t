#!/usr/bin/env perl
use strict;

use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::Requires 'Text::Markdown';
use Test::More tests => 38;

use lib '../..';

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::TextData;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir, 0, 1) if -e $test_dir;
mkdir($test_dir) unless -e $test_dir; 

chdir $test_dir or die $!;

#----------------------------------------------------------------------
# Create test data

do {
   my $text = <<'EOQ';
author: Bernie Simon
date: 2015-11-22T20:23:13
....
Page %%
--------

This is a paragraph.


    This is preformatted text.

* first %%
* second %%
* third %%
EOQ

    foreach my $count (qw(four three two one)) {
        my $output = $text;
        $output =~ s/%%/$count/g;

        my $filename = catfile($test_dir, "$count.md");
        fio_write_page($filename, $output);
        die "Didn't write $filename" unless -e $filename;
    }
};

#----------------------------------------------------------------------
# Create object

my %configuration = (top_directory => $test_dir,
                     base_directory => $test_dir,
                     title_template => '<h2></h2>',
                    );

my $obj = App::Followme::TextData->new(%configuration);

isa_ok($obj, "App::Followme::TextData"); # test 1
can_ok($obj, qw(new build)); # test 2

#----------------------------------------------------------------------
# Test conversion

do {
   my $index_file = $obj->dir_to_filename($test_dir);
    my $files = $obj->build('files', $index_file);
    foreach my $file (@$files) {

        my $page = fio_read_page($file);
        ok(length($page) > 0, "Read $file"); # test 3, 12, 21, 30

        my ($dir, $root) = fio_split_filename($file);
        my ($count, $suffix) = split(/\./, $root);

        my $filename = catfile($test_dir, "$count.$suffix");
        is($filename, $file, "filename check for $count"); # 4, 13, 22, 31

        my $section = $obj->fetch_sections($page);
        ok(length $section->{metadata} > 0, "found metadata in $count"); # test 5, 14, 23, 32
        ok(length $section->{body} > 0, "found body in $count"); # test 6, 15, 24, 33

        my $body = $obj->build('body', $file);
        ok(index($$body, "<li>third $count</li>") > 0,
           "Convert Text $count"); # test 7, 16, 25, 34

        my $title = $obj->build('title', $file,);
        is($$title, "Page $count", "get title $count"); # test 8, 17, 26, 35

        my $description = $obj->build('description', $file);
        is($$description, 'This is a paragraph.',
           "get description $count"); # test 9, 18, 27, 36

        my $date = $obj->build('date', $file);
        is($$date, 'Nov 22, 2015 20:23', "get date $count"); # test 10, 19, 28, 37

        my $author = $obj->build('author', $file);
        is($$author, 'Bernie Simon', "get author $count"); # test 11, 20, 29, 38
    }
};
