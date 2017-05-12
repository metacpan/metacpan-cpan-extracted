#!/usr/bin/perl -w

use strict;
use Test::More tests => 7;
use File::Spec::Functions qw(:ALL);

BEGIN { use_ok('Audio::FLAC::Header') };

#########################

{
        # Always test pure perl
        my @constructors = ('_new_PP');

        # Only test XS if built
        SKIP: {
                eval { Audio::FLAC::Header->_new_XS(catdir('data', 'picture.flac')) };
                skip "Not built with XS", 3 if $@;

                push @constructors, '_new_XS';
        }

        # Be sure to test both code paths.
        for my $constructor (@constructors) {

		my $flac = Audio::FLAC::Header->$constructor(catdir('data', 'picture.flac'));

		my $vendor      = $flac->vendor_string;
		my $has_picture = 1;
	
		if ($vendor =~ /libFLAC\s+(\d+\.\d+\.\d+)/) {

			if ($1 lt '1.1.3') {
				$has_picture = 0;
			}
		}

		SKIP: {
			skip "XS - No PICTURE support", 3 unless $has_picture;

			ok($flac, "constructor: $constructor");

			my $picture = $flac->picture();

			ok($picture, "found picture");

			ok($picture->{'mimeType'} eq 'image/jpeg', "found jpeg");
		}
	}
}

__END__
