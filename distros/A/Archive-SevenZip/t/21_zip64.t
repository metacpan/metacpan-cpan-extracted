#!/usr/bin/perl

# Test to make sure zip64 files are properly detected

use strict;
use warnings;

use Archive::SevenZip;
use File::Spec;

use Test::More tests => 2;

my $DATA_DIR = File::Spec->catfile('t', 'data');
my $ZIP_FILE = File::Spec->catfile($DATA_DIR, "zip64.zip");

my @errors = ();
#$Archive::Zip::ErrorHandler = sub { push @errors, @_ };
my $ar;
my $ok = eval { $ar = Archive::SevenZip->new($ZIP_FILE); 1 };
is $ok, 1, "We survive opening a zip64 file";
isa_ok $ar, 'Archive::SevenZip';
