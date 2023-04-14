#!/usr/bin/env perl
# AP-Client: CLI-based client / toolbox for ActivityPub
# Copyright © 2020-2023 AP-Client Authors <https://hacktivis.me/git/ap-client/>
# SPDX-License-Identifier: BSD-3-Clause
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'App::ActivityPubClient',
	ABSTRACT  => 'CLI-based client / toolbox for ActivityPub Client-to-Server',
	AUTHOR    => 'Haelwenn (lanodan) Monnier <contact+ap-client@hacktivis.me>',
	LICENSE   => 'bsd',
	VERSION   => 'v0.1.3',
	EXE_FILES =>
	  [ 'script/ap-fetch', 'script/ap-represent', 'script/ap-backup' ],
	MAN1PODS => {
		'script/ap-fetch' => 'blib/man1/ap-fetch.1',
		'script/ap-represent' => 'blib/man1/ap-represent.1',
		'script/ap-backup' => 'blib/man1/ap-backup.1',
	},
	PREREQ_PM => {
		'Exporter' => 0,
		'Getopt::Std' => 0,
		'HTTP::Request::Common' => 0,
		'JSON' => 0,
		'LWP::UserAgent' => 0,
		'MIME::Base64' => 0,
		'Scalar::Util' => 0,
	},
	TEST_REQUIRES => {
		'Test::More' => 0,
		'Test::Output' => 0,
	},
	META_MERGE => {
		'meta-spec'    => {version => 2},
		release_status => 'stable',
		resources      => {
			repository => {
				type => 'git',
				url  => 'https://hacktivis.me/git/ap-client.git/',
				web  => 'https://hacktivis.me/git/ap-client/',
			},
		},
	},
);
