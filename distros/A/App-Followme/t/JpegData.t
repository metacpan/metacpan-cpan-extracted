#!/usr/bin/env perl
use strict;

use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::Requires 'Image::Size';
use Test::More tests => 15;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::JpegData;

my $test_dir = catdir(@path, 'test');
my $data_dir = catdir(@path, 'tdata');

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;
chdir $test_dir or die $!;


my %configuration = (
                    top_directory => $test_dir,
                    base_directory => $test_dir,
                    extension => 'jpg',
                    target_prefix => 'img',
                    thumb_suffix => '-thumb',
                    );

#----------------------------------------------------------------------
# Create object

my $data = App::Followme::JpegData->new(%configuration);

isa_ok($data, "App::Followme::JpegData"); # test 1
can_ok($data, qw(new build)); # test 2

#----------------------------------------------------------------------
# Test target methods

do {
    my @files;
    foreach my $color (qw(red blue green)) {
        my $filename = '*.jpg';
        $filename =~ s/\*/$color/g;
        push(@files, $filename);
    }

    for (my $count = 0; $count < 3; $count++) {
        my $filename = @files[$count]; 
        my $target = $data->get_target($filename, \@files);
        my $ok =  'img' . ($count + 1);
        is($target, $ok, "get current target"); # test 3, 6, 9

        my $target = $data->get_target_next($filename, \@files);
        my $ok =  $count < 2 ? 'img' . ($count + 2) : '';
        is($target, $ok, "get next target"); # test 4, 7, 10

        my $target = $data->get_target_previous($filename, \@files);
        my $ok =  $count > 0 ? 'img' . $count : '';
        is($target, $ok, "get previous target"); # test 5, 8, 11
    }
};

#----------------------------------------------------------------------
# Test support routines

do {
    my $filename = catfile($test_dir, 'myphoto.jpg');
    my $thumbname = $data->get_thumb_file($filename);
    is($thumbname->[0], catfile($test_dir, 'myphoto-thumb.jpg'),
       'build thumb name'); # test 12

    is($data->{exclude}, '*-thumb.jpg', 'excluded files'); # test 13

    $filename = catfile($data_dir, 'red.jpg');
    my %dimension = $data->fetch_from_file($filename);

    is($dimension{height}, 200, 'fetch photo height'); # test 14
    is($dimension{width}, 200, 'fetch photo width'); # test 15
}
;
