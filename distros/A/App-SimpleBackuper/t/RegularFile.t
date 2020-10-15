#!/usr/bin/perl

use strict;
use warnings;
use Test::Spec;
use Encode;
use App::SimpleBackuper::RegularFile;

describe RegularFile => sub {
	it compress => sub {
		my $rf = bless { data => 'a' x 1000, options => { compression_level => 9 } } => 'App::SimpleBackuper::RegularFile';
		$rf->compress();
		ok length( $rf->{data} ) < 1000;
		$rf->decompress();
		is $rf->{data}, 'a' x 1000;
	};
	
	it crypt => sub {
		my $key = pack("C32", map {int rand 256} 1..32);
		my $iv = pack("C16", map {int rand 256} 1..16);
		my $data = 'a' x (length($key) * 10);
		Encode::_utf8_off($data);
		my $rf = bless { data => $data, options => { compression_level => 9 } } => 'App::SimpleBackuper::RegularFile';
		$rf->encrypt( $key, $iv );
		ok $rf->{data} ne $data;
		$rf->decrypt( $key, $iv );
		is $rf->{data}, $data;
	};
};

runtests unless caller;
