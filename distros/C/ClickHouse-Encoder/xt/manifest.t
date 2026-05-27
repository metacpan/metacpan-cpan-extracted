#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run manifest tests'
    unless $ENV{RELEASE_TESTING};

eval 'use Test::CheckManifest 0.9';
plan skip_all => 'Test::CheckManifest required' if $@;

ok_manifest({ filter => [qr/\.git/, qr/blib/, qr/MYMETA/, qr/Encoder\.[co]/, qr/\.bs$/, qr/\.tar\.gz$/, qr/^Makefile/, qr/pm_to_blib/] });
