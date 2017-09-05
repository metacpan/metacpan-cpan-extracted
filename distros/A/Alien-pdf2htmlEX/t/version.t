#!/usr/bin/env perl

use Test2::V0;
use Test::Alien;

use Alien::pdf2htmlEX;
use Alien::OpenJPEG;
use Alien::Poppler;
use Alien::FontForge;

use Capture::Tiny qw(capture_merged);

use lib 't/lib';

subtest "Run pdf2htmlEX" => sub {
	use Env qw(@LD_LIBRARY_PATH @DYLD_FALLBACK_LIBRARY_PATH @PATH);
	unshift @LD_LIBRARY_PATH, Alien::FontForge->rpath, Alien::Poppler->rpath;
	unshift @DYLD_FALLBACK_LIBRARY_PATH, Alien::FontForge->rpath, Alien::Poppler->rpath;
	unshift @PATH, Alien::FontForge->rpath, Alien::Poppler->rpath, Alien::OpenJPEG->rpath;

	alien_ok 'Alien::pdf2htmlEX';

	my $pdf2htmlEX = Alien::pdf2htmlEX->pdf2htmlEX_path;

	run_ok([ $pdf2htmlEX , '--version' ])
		->success
		->err_like(qr/pdf2htmlEX version (?<version>[\d.]+)/,
			'pdf2htmlEX output has version')
		->err_like(qr/pdf2htmlEX version \Q@{[ Alien::pdf2htmlEX->version ]}\E/,
			"the version matches what is installed: @{[ Alien::pdf2htmlEX->version ]}");
};

done_testing;
