#!/usr/bin/perl -T

use strict;
use warnings;

BEGIN {
	use Test::More;
	if (not $ENV {'TEST_AUTHOR'}) {
		plan ('skip_all' => 'Set $ENV{TEST_AUTHOR} to a true value to run the tests');
	}
}

BEGIN {
	eval 'use Test::CheckManifest';
	plan ('skip_all' => 'Test::CheckManifest required for testing the MANIFEST file') if $@;
}

ok_manifest ( { filter  => [qr{/\.}, qr{\.old$}, qr{cover_db/}, qr{t/99-}] } );
