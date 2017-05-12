#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;


WriteMakefile(
	NAME           => 'AnyEvent::UserAgent',
	AUTHOR         => 'Denis Ibaev <dionys@cpan.org>',
	VERSION_FROM   => 'lib/AnyEvent/UserAgent.pm',
	ABSTRACT_FROM  => 'lib/AnyEvent/UserAgent.pm',
	LICENSE        => 'perl',
	BUILD_REQUIRES => {
		'AnyEvent'              => 0,
		'HTTP::Request::Common' => 0,
		'Test::Deep'            => 0,
		'Test::More'            => 0,
	},
	PREREQ_PM      => {
		'namespace::clean'      => 0,
		'AnyEvent::HTTP'        => 0,
		'HTTP::Cookies'         => 0,
		'HTTP::Message'         => 0,
		'Moo'                   => 0,
	},
	META_MERGE     => {
		resources => {
			license     => 'http://dev.perl.org/licenses/',
			repository  => 'http://github.com/AdCampRu/anyevent-useragent',
			bugtracker  => 'http://github.com/AdCampRu/anyevent-useragent/issues',
		},
		no_index  => {directory => ['t']},
	},
	dist           => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
	clean          => {FILES => 'AnyEvent-UserAgent-*'},
	test           => {TESTS => 't/*.t'},
);
