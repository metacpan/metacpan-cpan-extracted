#!/usr/bin/perl -w

use strict;
use Test::More tests => 7;

use File::Spec::Functions qw(:ALL);
use File::Copy;

BEGIN { use_ok('Audio::FLAC::Header') };

#########################

{
        # Always test pure perl
        my @modes = ('PP');

        # Only test XS if built
        SKIP: {
                eval { Audio::FLAC::Header->_new_XS(catdir('data', 'empty.flac')) };
                skip "Not built with XS", 3 if $@;

                push @modes, 'XS';
        }

        # Be sure to test both code paths.
        for my $mode (@modes) {

		my $constructor  = "_new_$mode";
		my $write_method = "_write_$mode";

		my $empty = catdir('data', 'empty.flac');
		my $write = catdir('data', "write_$mode.flac");

		copy($empty, $write);

		my $flac = Audio::FLAC::Header->$constructor($write);

		ok($flac, "constructor: $constructor");

		my $tags = $flac->tags;

		$tags->{'ALBUM'} = 'FOO';

		ok($flac->$write_method, "Wrote out tags");

		undef $flac;

		my $read = Audio::FLAC::Header->$constructor($write);

		ok($read->tags('ALBUM') eq 'FOO', "Got written out tags");

		unlink($write);
	}
}

__END__
