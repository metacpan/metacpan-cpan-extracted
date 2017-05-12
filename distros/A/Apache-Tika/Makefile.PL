#!/usr/bin/env perl
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	ABSTRACT     => 'A Perl interface to the Apache Tika api',
	NAME         => 'Apache::Tika',
	VERSION_FROM => 'lib/Apache/Tika.pm',
	AUTHOR       => ['Gerard Ribugent Navarro', 'ribugent@cpan.org'],
	LICENSE      => 'gpl_2',
	PREREQ_PM    => {
		'Encode'         => 0,
		'LWP::UserAgent' => 0,
		'JSON::MaybeXS'  => 0
	},
	TEST_REQUIRES => {
		'Test::Compile' => '1.1.0',
		'Test::Pod'     => 0
	},
	META_MERGE => {
		"meta-spec" => {version => 2},
		resources   => {
			bugtracker => {
				web => "https://github.com/ribugent/perl-apache-tika/issues"
			},
			homepage   => 'https://github.com/ribugent/perl-apache-tika',
			repository => {
				type => 'git',
				url  => 'git://github.com/ribugent/perl-apache-tika.git',
				web  => 'https://github.com/ribugent/perl-apache-tika',
			},

		},

	}
);
