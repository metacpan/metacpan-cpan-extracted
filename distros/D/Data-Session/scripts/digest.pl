#!/usr/bin/env perl

use strict;
use warnings;

use Data::UUID;

use Digest::SHA;

use Digest::MD5;

# -------------------

my($digest);

for my $type (qw/create_bin create_hex create_str create_b64/)
{
	$digest = Data::UUID -> new -> $type;

	print "Data::UUID -> new -> $type. length(digest): ", length($digest), ". \n";
}

$digest = Digest::MD5 -> new -> add($$, time, rand(time) ) -> hexdigest;

print "Digest::MD5 -> new -> add(...) -> hexdigest. length(digest): ", length($digest), ". \n";

for my $bits (1, 256, 512)
{
	$digest = Digest::SHA -> new($bits) -> add($$, time, rand(time) ) -> hexdigest;

	print "Digest::SHA -> new($bits). length(digest): ", length($digest), ". \n";
}
