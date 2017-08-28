#!/usr/bin/env perl

use Test::Most tests => 1;
use Alien::OpenJPEG;
use Alien::Poppler;
use Capture::Tiny qw(capture_merged);

subtest "pdftotext utility" => sub {
	use Env qw(@LD_LIBRARY_PATH @DYLD_FALLBACK_LIBRARY_PATH @PATH);
	unshift @LD_LIBRARY_PATH, Alien::Poppler->rpath;
	unshift @DYLD_FALLBACK_LIBRARY_PATH, Alien::Poppler->rpath;
	unshift @PATH, Alien::Poppler->rpath, Alien::OpenJPEG->rpath;

	my $pdftotext = Alien::Poppler->pdftotext_path;

	my ($merged, $result) = capture_merged {
		system($pdftotext, qw(-v));
	};

	my $version_match_re = qr/pdftotext version (?<version>[\d.]+)/;

	like $merged, $version_match_re, 'pdftotext output has version';

	$merged =~ $version_match_re;
	is $+{version}, Alien::Poppler->version, "the version matches what is installed: @{[ Alien::Poppler->version ]}";
};

done_testing;
