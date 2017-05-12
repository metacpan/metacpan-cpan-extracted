#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;


WriteMakefile(
	NAME             => 'AnyEvent::Delay::Simple',
	AUTHOR           => 'Denis Ibaev <dionys@cpan.org>',
	VERSION_FROM     => 'lib/AnyEvent/Delay/Simple.pm',
	ABSTRACT_FROM    => 'lib/AnyEvent/Delay/Simple.pm',
	LICENSE          => 'perl',
	MIN_PERL_VERSION => '5.8.1',
	BUILD_REQUIRES   => {
		'Test::Deep'        => 0,
		'Test::More'        => 0,
	},
	PREREQ_PM        => {
		'parent'            => 0,
		'AnyEvent'          => 0,
		'Scalar::Util'      => 0,
	},
	META_MERGE       => {
		resources => {
			license     => 'http://dev.perl.org/licenses/',
			repository  => 'http://github.com/AdCampRu/anyevent-delay-simple',
			bugtracker  => 'http://github.com/AdCampRu/anyevent-delay-simple/issues',
		},
		no_index  => {directory => ['t']},
	},
	dist             => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
	clean            => {FILES => 'AnyEvent-Delay-Simple-*'},
	test             => {TESTS => 't/*.t'},
);
