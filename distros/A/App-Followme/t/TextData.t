#!/usr/bin/env perl
use strict;

use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::Requires 'Text::Markdown';
use Test::More tests => 26;

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

rmtree($test_dir) if -e $test_dir;
mkdir $test_dir or die $!;
chmod 0755, $test_dir;

my $sub_dir = catfile(@path, "test", "sub");
mkdir $sub_dir or die $!;
chmod 0755, $sub_dir;
chdir $test_dir or die $!;

#----------------------------------------------------------------------
# Create test data

do {
   my $text = <<'EOQ';
----
author: Bernie Simon
date: 2015-11-22T20:23:13
----
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
        ok(length($page) > 0, "Read $file"); # test 3, 9, 15, 21

        my ($dir, $root) = fio_split_filename($file);
        my ($count, $suffix) = split(/\./, $root);

        my $body = $obj->build('body', $file);
        ok(index($$body, "<li>third $count</li>") > 0,
           "Convert Text $count"); # test 4, 10, 16, 22

        my $title = $obj->build('title', $file,);
        is($$title, "Page $count", "get title $count"); # test 5, 11, 17, 23

        my $description = $obj->build('description', $file);
        is($$description, 'This is a paragraph.',
           "get description $count"); # test 6, 12, 18, 24

        my $date = $obj->build('date', $file);
        is($$date, 'Nov 22, 2015 20:23', "get date $count"); # test 7, 13, 19, 25

        my $author = $obj->build('author', $file);
        is($$author, 'Bernie Simon', "get author $count"); # test 8, 14, 20, 26
    }
};
