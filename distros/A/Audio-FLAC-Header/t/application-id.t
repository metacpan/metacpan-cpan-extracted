#!/usr/bin/perl -w

use strict;
use Test::More tests => 11;
use File::Spec::Functions qw(:ALL);

BEGIN { use_ok('Audio::FLAC::Header') };

#########################

{
	# Always test pure perl
	my @constructors = ('_new_PP');

	# Only test XS if built
	SKIP: {
		eval { Audio::FLAC::Header->_new_XS(catdir('data', 'appId.flac')) };
		skip "Not built with XS", 5 if $@;

		push @constructors, '_new_XS';
	}

	# Be sure to test both code paths.
	for my $constructor (@constructors) {

		my $flac = Audio::FLAC::Header->$constructor(catdir('data', 'appId.flac'));

		ok($flac, "constructor: $constructor");

		my $info = $flac->info();

		ok($info, "info exists");

		my $cue = $flac->cuesheet();

		ok($cue, "cue sheet exists");

		my $app = $flac->application(1835361648);

		ok($app, "application block exists");

		ok($app =~ /musicbrainz/, "found musicbrainz block");
	}
}

__END__
