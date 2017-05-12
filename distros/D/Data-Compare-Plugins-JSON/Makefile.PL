#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;


WriteMakefile(
	NAME             => 'Data::Compare::Plugins::JSON',
	AUTHOR           => 'Denis Ibaev <dionys@cpan.org>',
	VERSION_FROM     => 'lib/Data/Compare/Plugins/JSON.pm',
	ABSTRACT_FROM    => 'lib/Data/Compare/Plugins/JSON.pm',
	LICENSE          => 'perl',
	MIN_PERL_VERSION => '5.8.0',
	BUILD_REQUIRES   => {
		'Test::More'    => 0,
	},
	PREREQ_PM        => {
		'Data::Compare' => 0,
	},
	META_MERGE       => {
		resources => {
			license     => 'http://dev.perl.org/licenses/',
			repository  => 'http://github.com/dionys/data-compare-plugins-json',
			bugtracker  => 'http://github.com/dionys/data-compare-plugins-json/issues',
		},
		no_index  => {directory => ['t']},
	},
	dist             => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
	clean            => {FILES => 'Data-Compare-Plugins-JSON-*'},
	test             => {TESTS => 't/*.t'},
);
