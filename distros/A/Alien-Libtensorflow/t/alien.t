#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use Test::Alien;
use Alien::Libtensorflow;

alien_ok 'Alien::Libtensorflow';
ffi_ok { symbols => ['TF_Version'] }, with_subtest {
	my($ffi) = @_;
	my $get_version = $ffi->function( TF_Version => [], 'string' );
	my $version = $get_version->call();
	note $version;
	like $version, qr/^[0-9.]+/;
};

done_testing;
