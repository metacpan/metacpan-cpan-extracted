#!/usr/bin/env perl
use strict;

use Cwd;
use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catfile catdir rel2abs splitdir);

use Test::Requires 'Text::Markdown';
use Test::More tests => 18;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme;
require App::Followme::Initialize;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;

chdir $test_dir or die $!;
$test_dir = cwd();

#----------------------------------------------------------------------
# Initialize web site

do {
    App::Followme::Initialize::initialize($test_dir);
    ok(-e '_templates', 'Created templates directory'); # test 1
    ok(-e 'essays', 'Created essays directory'); # test 2
    ok(-e 'photos', 'Created essays directory'); # test 3
    ok(-e 'followme.cfg', 'Created configuration file'); # test 4
};

#----------------------------------------------------------------------
# Create index page

do {
    chdir($test_dir) or die $!;
    my $followme = App::Followme->new();

    my $text = "This is the top page\n";
    fio_write_page('index.md', $text);
    $followme->run($test_dir);

    ok(-e 'index.html', 'Index file created'); #test 5
    ok(! -e 'index.md', 'Text file deleted'); #test 6

    chomp($text);
    my $page = fio_read_page('index.html');
    ok(index($page, '<h2>Test</h2>') > 0, 'Generated title'); # test 7
    ok(index($page, "<p>$text</p>") > 0, 'Generated body'); # test 8

};

#----------------------------------------------------------------------
# Create essay pages

do {
    chdir($test_dir) or die $!;
    my $followme = App::Followme->new();

    my $path = catfile($test_dir, 'essays');
    foreach my $dir (qw(archive)) {
        $path = catfile($path, $dir);
        mkdir($path);
        chmod 0755, $path;
    }

    foreach my $count (qw(first second third)) {
        my $file = "$count.md";
        $file = catfile($path, $file);

        my $text = "$count blog post.\n";
        fio_write_page($file, $text);

        $followme->run($path);
        $file =~ s/md$/html/;
        sleep(2);

        chomp($text);
        my $page = fio_read_page($file);
        ok(index($page, "<p>$text</p>") > 0,
           "Generated $count blog post"); # test 9-11
    }

    $path = catfile($test_dir, 'essays');
    my $file = catfile($path, 'index.html'); # test 12
    ok(-e $file, "essays index file created");

    foreach my $dir (qw(archive)) {
        my $page = fio_read_page($file);
        ok(index($page, "$dir/index.html") > 0,
           "Link to $dir directory"); # test 13

        $path = catfile($path, $dir);
        $file = catfile($path, 'index.html');
        ok(-e $file, "$dir index file created"); # test 14
    }
};

#----------------------------------------------------------------------
# Create photo gallery

do {
    my $data_dir = catfile($test_dir, 'tdata');
    my $gallery_dir = catfile($test_dir, 'photos');

    foreach my $color (qw(red green blue)) {
        my $photo_name = '*.jpg';
        my $thumb_name = '*-photo-thumb.jpg';

        for my $filename (($photo_name, $thumb_name)) {
            $filename =~ s/\*/$color/g;

            my $input_file = catfile($data_dir, $filename);
            my $output_file = catfile($gallery_dir, $filename);

            my $photo = fio_read_page($input_file, ':raw');
            fio_write_page($output_file, ':raw');
        }
    }

    chdir($gallery_dir) or die $!;
    my $followme = App::Followme->new();
    $followme->run($gallery_dir);

    my $gallery_name = catfile($gallery_dir, 'index.html'); 
    ok(-e $gallery_name,  "Gallery index file created"); # test 15

    my $page = fio_read_page($gallery_name);
    my @items = $page =~ m/(<div class="lightbox")/g;
    is(@items, 3, 'Index three photos'); # test 16
};

#----------------------------------------------------------------------
# Create help

do {
    my $help_dir = catfile($test_dir, 'help');
    chdir($help_dir) or die $!;

    my $followme = App::Followme->new();
    $followme->run($help_dir);

    my $help_name = catfile($help_dir, 'index.html'); 
    ok(-e $help_name,  "Help index file created"); # test 17

    my $page = fio_read_page($help_name);
    my @items = $page =~ m/(<dt>)/g;
    ok(@items > 25, 'Index help'); # test 18
};
