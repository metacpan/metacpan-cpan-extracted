#!/usr/bin/perl

use strict;
use warnings;

use File::Copy;
use File::Path;
use File::Find;
use File::Basename;

my ($target) = @ARGV;

my @libs = glob "lib/*.a";
my @headers;

find({
    wanted => sub {
        return unless -f $_ && /\b\.h$/;
        push @headers, $_;
    },
    no_chdir => 1,
}, 'upb');

for my $lib (@libs) {
    my $dest = "$target/$lib";

    mkpath(dirname($dest));
    copy($lib, $dest) or die "Error copying '$lib' to '$dest': $!";
}

for my $header (@headers) {
    my $dest = "$target/include/$header";

    mkpath(dirname($dest));
    copy($header, $dest) or die "Error copying '$header' to '$dest': $!";
}
