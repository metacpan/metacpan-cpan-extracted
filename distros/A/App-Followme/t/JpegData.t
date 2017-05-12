#!/usr/bin/env perl
use strict;

use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::Requires 'GD';
use Test::More tests => 6;

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
mkdir $test_dir;
chdir $test_dir;

my %configuration = (
\                   extension => 'jpg',
                    thumb_suffix => '-thumb',
                    );

#----------------------------------------------------------------------
# Create object

my $data = App::Followme::JpegData->new(%configuration);
isa_ok($data, "App::Followme::JpegData"); # test 1
can_ok($data, qw(new build)); # test 2

#----------------------------------------------------------------------
# Test support routines

do {
    foreach my $count (qw(first second third)) {
        my $filename = '*-photo.jpg';
        $filename =~ s/\*/$count/g;

    }
};

#----------------------------------------------------------------------
# Test support routines

do {
    my $filename = catfile($test_dir, 'myphoto.jpg');
    my $thumbname = $data->get_thumb_file($filename);
    is($thumbname->[0], catfile($test_dir, 'myphoto-thumb.jpg'),
       'build thumb name'); # test 3

    is($data->{exclude}, '*-thumb.jpg', 'excluded files'); # test 4

    $filename = catfile($data_dir, 'first-photo.jpg');
    my %dimension = $data->fetch_from_file($filename);

    is($dimension{height}, 750, 'fetch photo height'); # test 5
    is($dimension{width}, 750, 'fetch photo width'); # test 6
}
;
