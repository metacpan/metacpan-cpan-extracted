#!/usr/bin/env perl
use strict;

use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 4;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

require App::Followme::UploadNone;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;

my %configuration = (
                     top_directory => $test_dir,
                    );

#----------------------------------------------------------------------
# Test

do {
    my $up = App::Followme::UploadNone->new(%configuration);

    my $user = 'user';
    my $password = 'password';

    my $dir = 'subdir';
    my $remote_file = 'filename';
    my $local_file = catfile($dir, $remote_file);

    $up->open($user, $password);
    my $flag =$up->add_directory($dir);
    is($flag, 1, 'Mock add directory'); # test 1

    $flag = $up->add_file($local_file, $remote_file);
    is($flag, 1, 'Mock add file'); # test 2

    $flag = $up->delete_directory($dir);
    is($flag, 1, 'Mock delete directory'); # test 3

    $flag = $up->delete_file($remote_file);
    is($flag, 1, 'Mock delete file'); # test 4

    $up->close();
};
