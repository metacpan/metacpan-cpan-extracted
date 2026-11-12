#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp qw(tempdir);
use Data::Shared;

my $dir = tempdir(CLEANUP => 1);
my $root = Data::Shared->new($dir);
$root->mount($_, 'hashmap:ii', undef, 100) for qw(live archive);
$root->set('/live/1', 10);
$root->set('/archive/7', 70);
my $file = $root->mount_info('archive')->{file};

$root->unmount('archive');
print "unmounted: storage retained=", (-f $file ? 1 : 0), "\n";
undef $root;
$root = Data::Shared->open($dir);
print "reopened mounts: ", join(', ', $root->mounts), "\n";

$root->mount('archive', 'hashmap:ii', undef, 100);
print "adopted retained data: ", $root->get('/archive/7'), "\n";
$root->unmount('archive', unlink => 1);
print "retired: storage retained=", (-e $file ? 1 : 0), "\n";
die "retirement left storage behind\n" if -e $file;

$root->mount('archive', 'hashmap:ii', undef, 100);
print "fresh mount has old key: ", $root->exists('/archive/7'), "\n";
$root->unmount('archive', unlink => 1);
print "live mount still serving: ", $root->incr('/live/1'), "\n";
