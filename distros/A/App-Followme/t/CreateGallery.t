#!/usr/bin/env perl
use strict;

use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::Requires 'GD';
use Test::More tests => 15;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::CreateGallery;

my $test_dir = catdir(@path, 'test');
my $data_dir = catdir(@path, 'tdata');

rmtree($test_dir);
mkdir $test_dir;
chdir $test_dir;

my $template_name = catfile($test_dir, 'gallery_template.htm');

my %configuration = (
                    template_file => $template_name,
                    thumb_suffix => '-thumb',
                    web_extension => 'html',
                    photo_height => 600,
                    thumb_height => 150,
                    );

#----------------------------------------------------------------------
# Test support routines

do {
    my $gal = App::Followme::CreateGallery->new(%configuration);

    my %new_configuration = %configuration;
    $new_configuration{photo_height} = 600;
    $new_configuration{thumb_height} = 150;
    $gal = App::Followme::CreateGallery->new(%new_configuration);
    my ($width, $height) = $gal->new_size('photo', 1800, 1200);
    is($width, 900, 'photo width'); # test 1
    is($height, 600, 'photo height'); # test 2

    %new_configuration = %configuration;
    $new_configuration{photo_width} = 600;
    $new_configuration{thumb_width} = 150;
    $gal = App::Followme::CreateGallery->new(%new_configuration);
    ($width, $height) = $gal->new_size('thumb', 1800, 1200);
    is($width, 150, 'thumb width'); # test 3
    is($height, 100, 'thumb height'); # test 4
};

#----------------------------------------------------------------------
# Create gallery

do {
   my $gallery_template = <<'EOQ';
<html>
<head>
<meta name="robots" content="noarchive,follow">
<!-- section meta -->
<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<!-- section primary -->
<h1>$title</h1>
<!-- endsection primary -->

<!-- section secondary -->
<ul>
<!-- for @files -->
<!-- for @thumb_file -->
<li><img src="$url" width="$width" height="$height" /><br />
<!-- endfor -->
<a href="$url">$title</a></li>
<!-- endfor -->
</ul>
<!-- endsection secondary -->
</body>
</html>
EOQ

    fio_write_page($template_name, $gallery_template);

    my $gallery_dir = catfile($test_dir, 'gallery');
    mkdir($gallery_dir);
    chdir($gallery_dir);

    my $gal = App::Followme::CreateGallery->new(%configuration);

    my @photo_files;
    my @thumb_files;
    foreach my $count (qw(first second third)) {
        my $filename = '*-photo.jpg';
        $filename =~ s/\*/$count/g;

        my $input_file = catfile($data_dir, $filename);
        my $output_file = catfile($gallery_dir, $filename);

        my $photo = $gal->{data}->read_photo($input_file);
        $gal->write_photo($output_file, $photo);
        ok(-e $output_file, "read and write photo $count"); # test 5-7

        push(@photo_files, $output_file);
        my $thumb_file = $gal->{data}->get_thumb_file($output_file);
        push(@thumb_files, $thumb_file->[0]);
    }

    my $title = $gal->{data}->build('$title', $photo_files[0]);
    is($$title, 'First Photo', 'First page title'); # test 8

    my $url = $gal->{data}->build('url', $photo_files[1]);
    is($$url, 'second-photo.jpg', 'Second page url'); # test 9

    $url = $gal->{data}->build('url', $thumb_files[2]);
    is($$url, 'third-photo-thumb.jpg', 'Third page thumb url'); # test 10

    $gal->run($gallery_dir);

    foreach my $i (1 .. 3) {
        ok(-e $thumb_files[$i-1], "Create thumb $i"); # test 11-13
    }

    my $gallery_name = fio_to_file($gallery_dir, 'html');
    ok(-e $gallery_name, 'Create index file'); # test 14

    my $page = fio_read_page($gallery_name);
    my @items = $page =~ m/(<li>)/g;
    is(@items, 3, 'Index three photos'); # test 15
};
