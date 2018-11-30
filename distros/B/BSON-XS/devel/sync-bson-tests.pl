#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use utf8;
use open qw/:std :utf8/;

use Path::Tiny;

# Assumes that
my $root = path($0)->parent(2);

my $path_to_bsonpm = shift(@ARGV);
die "Usage: $0 <path-to-bson>\n" unless $path_to_bsonpm;

my $bsonpm = path($path_to_bsonpm);
die "'$bsonpm' doesn't look like a path containing BSON.pm\n"
  unless $bsonpm->child(qw/lib BSON.pm/)->exists;

sub try_system {
    my @command = @_;
    say "Running: @command";
    system(@command) and die "Aborting: '@command' failed";
}

sub rsync {
    my ($dir) = @_;
    try_system( 'rsync', '-a', '--delete', $bsonpm->child("corpus"), $root );
    try_system( 'rsync', '-a', '--delete', $bsonpm->child(qw/t common/),
        $root->child("t") );
    try_system( 'rsync', '-a', '--delete', $bsonpm->child(qw/t corpus/),
        $root->child("t") );
    try_system( 'rsync', '-a', '--delete', $bsonpm->child(qw/t lib/),
        $root->child("t") );
    try_system( 'rsync', '-a', '--delete', $bsonpm->child(qw/t mapping/),
        $root->child("t") );
    try_system( 'rsync', '-a', '--delete', $bsonpm->child(qw/t regression/),
        $root->child("t") );
}

rsync();
