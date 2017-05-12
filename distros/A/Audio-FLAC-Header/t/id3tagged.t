#!/usr/bin/perl -w

use strict;
use Test::More tests => 9;
use File::Spec::Functions qw(:ALL);

BEGIN { use_ok('Audio::FLAC::Header') };

#########################

{
        # Always test pure perl
        my @constructors = ('_new_PP');

        # Only test XS if built
        SKIP: {
                eval { Audio::FLAC::Header->_new_XS(catdir('data', 'id3tagged.flac')) };
                skip "Not built with XS", 4 if $@;

                push @constructors, '_new_XS';
        }

        # Be sure to test both code paths.
        for my $constructor (@constructors) {

		my $flac = Audio::FLAC::Header->$constructor(catdir('data', 'id3tagged.flac'));

		ok($flac, "constructor: $constructor");

		my $info = $flac->info();

		ok($info, "info block");

		my $tags = $flac->tags();

		ok($tags, "tags read");

		ok($tags->{'title'} =~ /Allegro Maestoso/, "found title");
	}
}

__END__
