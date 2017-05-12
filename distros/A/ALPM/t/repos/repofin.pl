#!/usr/bin/env perl

use File::Basename;

unless(@ARGV == 1){
	print STDERR "usage: $0 [repo dir path]\n";
	exit 2;
}

$dir = shift;
unless(-d $dir){
	print STDERR "$0: repo dir $dir does not exist\n";
	exit 1;
}

$name = basename($dir);
$dir = "$dir/contents";
unless(-d $dir){
	print STDERR "$0: the specified repo dir must contain a 'contents' dir\n";
	exit 1;
}

chdir $dir or die "chdir: $!";
system "bsdtar -cf - * | gzip -c > ../$name.db";
if($? || !-f "../$name.db"){
	print STDERR "$0: failed to create tarball\n";
	exit 1;
}

chdir '..' or die "chdir: $!";
system 'rm -r contents';

exit 0;
