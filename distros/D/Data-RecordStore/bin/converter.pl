#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Data::RecordStore;

die "Converter requires Data::RecordStore version of at least 2.0" unless $Data::RecordStore::VERSION >= 2;

my( $source_dir, $dest_dir ) = @ARGV;
Data::RecordStore::convert( $source_dir, $dest_dir );
