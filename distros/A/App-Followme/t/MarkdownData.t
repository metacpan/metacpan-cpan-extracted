#!/usr/bin/env perl
use strict;

use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::Requires 'Text::Markdown';
use Test::More tests => 22;

use lib '../..';

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::MarkdownData;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir;
chmod 0755, $test_dir;
mkdir catfile($test_dir, "sub");
chmod 0755, catfile($test_dir, "sub");
chdir $test_dir;

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

This is a paragraph


    This is preformatted text.

* first %%
* second %%
* third %%
EOQ

    foreach my $count (qw(four three two one)) {
        my $output = $text;
        $output =~ s/%%/$count/g;

        my $filename = "$count.md";
        fio_write_page($filename, $output);
    }
};

#----------------------------------------------------------------------
# Create object

my $obj = App::Followme::MarkdownData->new(current_directory => $test_dir,
                                           title_template => '<h2></h2>',);
isa_ok($obj, "App::Followme::MarkdownData"); # test 1
can_ok($obj, qw(new build)); # test 2

#----------------------------------------------------------------------
# Test conversion

do {
   my $index_file = $obj->dir_to_filename($test_dir);
    my $files = $obj->build('files', $index_file);
    foreach my $file (@$files) {
        my ($dir, $root) = fio_split_filename($file);
        my ($count, $suffix) = split(/\./, $root);

        my $body = $obj->build('body', $file);
        ok(index($$body, "<li>third $count</li>") > 0,
           "Convert Text $count"); # test 3, 8, 13, 18

        my $title = $obj->build('title', $file,);
        is($$title, "page $count", "get title $count"); # test 4, 9. 14, 19

        my $description = $obj->build('description', $file);
        is($$description, 'This is a paragraph',
           "get description $count"); # test 5, 10, 15, 20

        my $date = $obj->build('date', $file);
        is($$date, '2015-11-22T20:23:13', "get date $count"); # test 6, 11, 16, 21

        my $author = $obj->build('author', $file);
        is($$author, 'simon bernie', "get author $count"); # test 7, 12, 17, 22
    }
};
