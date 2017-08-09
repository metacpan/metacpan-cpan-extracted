#!/usr/bin/perl
use strict;
use warnings;

use File::Temp qw/tempdir/;
use File::Slurp;
use File::Spec::Functions;
use Image::Magick;

use Test::More tests => 11;
BEGIN { use_ok('App::Gallery') };

sub test_img_size {
	my ($width, $height, $file) = @_;
	my $image = Image::Magick->new;
	$image->Read($file);
	my ($actual_width, $actual_height) = $image->Get(qw/width height/);
	is $width, $actual_width, 'image width';
	is $height, $actual_height, 'image height';
}

my @imgs = <t/*.png>;
my $dir = tempdir ('app-gallery.XXXX', TMPDIR => 1, CLEANUP => 1);
my $dir1 = catdir $dir, 'test1';
my $dir2 = catdir $dir, 'test2';

App::Gallery->run({out => $dir1, title => 'Some title', width => 200, height => 200}, @imgs);

my $html = read_file catfile $dir1, 'index.html';
is $html, <<'EOF', 'index.html as expected';
<!DOCTYPE html>
<title>Some title</title>
<meta charset="utf-8">
<style>
.imgwrap {
        display: inline-block;
        margin: 6px 3px;
        vertical-align: center;
        text-align: center;
}
</style>
<link rel="stylesheet" href="style.css">

<h1>Some title</h1>
<div>
<div class=imgwrap><a href='full/100x400.png'><img src='thumb/100x400.png'></a></div>
<div class=imgwrap><a href='full/800x200.png'><img src='thumb/800x200.png'></a></div>
</div>
EOF

test_img_size (50, 200, catfile $dir1, 'thumb', '100x400.png');
test_img_size (200, 50, catfile $dir1, 'thumb', '800x200.png');

App::Gallery->run({out => $dir2, tmpl => catfile 't', 'example-tmpl'}, @imgs);

$html = read_file catfile $dir2, 'index.html';
is $html, <<'EOF', 'index.html as expected';
<!DOCTYPE html>
<title>Gallery</title>
<meta charset="utf-8">
<link rel="stylesheet" href="style.css">

<div>
<div><a href='full/100x400.png'><img src='thumb/100x400.png'></a></div>
<div><a href='full/800x200.png'><img src='thumb/800x200.png'></a></div>
</div>
EOF

test_img_size (100, 400, catfile $dir2, 'thumb', '100x400.png');
test_img_size (600, 150, catfile $dir2, 'thumb', '800x200.png');
