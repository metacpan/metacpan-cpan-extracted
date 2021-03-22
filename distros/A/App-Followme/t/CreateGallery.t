#!/usr/bin/env perl
use strict;

use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::Requires 'Image::Size';
use Test::More tests => 5;

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
my $photo_dir = catdir($test_dir, 'photos');

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;
chdir $test_dir  or die $!;

my $gallery_dir = catfile($test_dir, 'gallery');
mkdir($gallery_dir) unless -e $gallery_dir;
chmod 0755, $gallery_dir;

my $template_name = catfile($test_dir, 'gallery_template.htm');

my %configuration = (top_directory => $test_dir,
                    base_directory => $gallery_dir,
                    template_file => $template_name,
                    thumb_suffix => '-thumb',
                    web_extension => 'html',
                    );

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

    chdir($gallery_dir);
    my $gal = App::Followme::CreateGallery->new(%configuration);

    my @photo_files;
    my @thumb_files;
    foreach my $color (qw(red green blue)) {
        my $filename = '*.jpg';
        $filename =~ s/\*/$color/g;

        my $input_file = catfile($data_dir, $filename);
        my $output_file = catfile($gallery_dir, $filename);

        my $photo = fio_read_page($input_file, ':raw');
        fio_write_page($output_file, $photo, ':raw');

        push(@photo_files, $output_file);
        my $thumb_file = $gal->{data}->get_thumb_file($output_file);
        push(@thumb_files, $thumb_file->[0]);
    }

    my $title = $gal->{data}->build('$title', $photo_files[0]);
    is($$title, 'Red', 'Red page title'); # test 1

    my $url = $gal->{data}->build('url', $photo_files[1]);
    is($$url, 'gallery/green.jpg', 'Green photo url'); # test 2

    $url = $gal->{data}->build('url', $thumb_files[2]);
    is($$url, 'gallery/blue-thumb.jpg', 'Blue photo thumb url'); # test 3

    $gal->run($gallery_dir);

    my $gallery_name = fio_to_file($gallery_dir, 'html');
    ok(-e $gallery_name, 'Create index file'); # test 4

    my $page = fio_read_page($gallery_name);
    my @items = $page =~ m/(<li>)/g;
    is(@items, 3, 'Index three photos'); # test 5
};
