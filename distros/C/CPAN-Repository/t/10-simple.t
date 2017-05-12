#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw/ tempfile tempdir /;

use CPAN::Repository;

BEGIN {

	my $tempdir = tempdir;

	{
		my $repo = CPAN::Repository->new({
			dir => $tempdir,
			url => 'http://cpan.universe.org/',
			written_by => '10-simple.t',
		});

		isa_ok($repo,'CPAN::Repository');

		ok(!$repo->is_initialized,'Checking if repo is not initialized');
		
		$repo->initialize;

		ok($repo->is_initialized,'Checking if repo is now initialized');

		$repo->add_author_distribution('ALMIGHTYGOD',"$Bin/data/My-Sample-Distribution-0.003.tar.gz");
		$repo->add_author_distribution('FAMILYGUY',"$Bin/data/My-Other-Sample-0.001.tar.gz");

		my @lines = $repo->packages->get_file_lines;
		
		is(scalar @lines, 11, 'Checking for correct amount of lines in packages');
	}

	my $repo = CPAN::Repository->new({
		dir => $tempdir,
		url => 'http://cpan.universe.org/',
		written_by => '10-simple.t',
	});

	isa_ok($repo,'CPAN::Repository');

	ok($repo->is_initialized,'Checking if repo is still initialized');

	$repo->add_author_distribution('ALMIGHTYGOD',"$Bin/data/My-Sample-Distribution-0.004.tar.gz",'THIS_IS_SOOO_GOOD');

	is_deeply($repo->packages->modules, {
		'My::Other::Sample' => [ '0.001', 'F/FA/FAMILYGUY/My-Other-Sample-0.001.tar.gz' ],
		'My::Sample::Distribution' => [ '0.004', 'THIS_IS_SOOO_GOOD/My-Sample-Distribution-0.004.tar.gz' ]
	}, 'Checking module state of the packages file');

	is_deeply($repo->modules, {
		'My::Other::Sample' => $tempdir.'/authors/id/F/FA/FAMILYGUY/My-Other-Sample-0.001.tar.gz',
		'My::Sample::Distribution' => $tempdir.'/authors/id/THIS_IS_SOOO_GOOD/My-Sample-Distribution-0.004.tar.gz'
	}, 'Checking module state of the repository');
	
	my @packages_lines = grep { $_ !~ /^Last-Updated:/ } map { chomp($_); $_; } $repo->packages->get_file_lines;

	is_deeply(\@packages_lines, [
		'File:         02packages.details.txt',
		'URL:          http://cpan.universe.org/modules/02packages.details.txt',
		'Description:  Package names found in directory $CPAN/authors/id/',
		'Columns:      package name, version, path',
		'Intended-For: Automated fetch routines, namespace documentation.',
		'Written-By:   10-simple.t',
		'Line-Count:   2',
		'',
		'My::Other::Sample                                            0.001                F/FA/FAMILYGUY/My-Other-Sample-0.001.tar.gz',
		'My::Sample::Distribution                                     0.004                THIS_IS_SOOO_GOOD/My-Sample-Distribution-0.004.tar.gz'
	], 'Checking for correct lines in packages');

	my @mailrc_lines = map { chomp($_); $_; } $repo->mailrc->get_file_lines;

	is_deeply(\@mailrc_lines, [
		'alias ALMIGHTYGOD "ALMIGHTYGOD"',
		'alias FAMILYGUY "FAMILYGUY"'
	], 'Checking for correct lines in mailrc');

	isa_ok($repo->timestamp,'DateTime');
	
}

done_testing;
