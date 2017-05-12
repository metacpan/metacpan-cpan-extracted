#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Stream::Bulk::Path::Class;

use Path::Class;

my $dist = file(__FILE__)->parent->parent;

foreach my $dir ( $dist->subdir("t"), $dist->subdir("lib"), $dist ) {

	{
		my $paths = Data::Stream::Bulk::Path::Class->new(
			dir => $dir,
			chunk_size => 2,
			depth_first => 0,
		);

		my $strings = $paths->filter(sub {[ grep { !/tmp/ } map { "$_" } @$_ ]});

		my @rec;
		$dir->recurse( callback => sub { push @rec, "$_[0]" unless $_[0] =~ /tmp/ }, depthfirst => 0, preorder => 1 );

		ok( !$_->is_done, "not done" ) for $paths, $strings;

		my @all = $strings->all;

		ok( $_->is_done, "done" ) for $paths, $strings;

		is_deeply(
			[ sort @all ],
			[ sort @rec ],
			"breadth first traversal path set",
		);

		is_deeply(
			\@all,
			\@rec,
			"breadth first traversal order",
		);
	}

	{
		my $paths = Data::Stream::Bulk::Path::Class->new(
			dir => $dir,
			chunk_size => 2,
			depth_first => 1,
		);

		my $strings = $paths->filter(sub {[ grep { !/tmp/ } map { "$_" } @$_ ]});

		my @rec;
		$dir->recurse( callback => sub { push @rec, "$_[0]" unless $_[0] =~ /tmp/ }, depthfirst => 1, preorder => 1 );

		ok( !$_->is_done, "not done" ) for $paths, $strings;

		my @all = $strings->all;

		ok( $_->is_done, "done" ) for $paths, $strings;

		is_deeply(
			[ sort @all ],
			[ sort @rec ],
			"depth first traversal path set",
		);

		is_deeply(
			\@all,
			\@rec,
			"depth first traversal order",
		);
	}

	{
		my $paths = Data::Stream::Bulk::Path::Class->new(
			dir => $dir,
			chunk_size => 2,
			depth_first => 0,
			only_files => 1,
		);

		my $strings = $paths->filter(sub {[ grep { !/tmp/ } map { "$_" } @$_ ]});

		my @rec;
		$dir->recurse( callback => sub { push @rec, "$_[0]" if $_[0] !~ /tmp/ and -f $_[0] }, depthfirst => 0, preorder => 1 );

		ok( !$_->is_done, "not done" ) for $paths, $strings;

		my @all = $strings->all;

		ok( $_->is_done, "done" ) for $paths, $strings;

		is_deeply(
			[ sort @all ],
			[ sort @rec ],
			"breadth first traversal path set",
		);

		is_deeply(
			\@all,
			\@rec,
			"breadth first traversal order",
		);
	}
}

done_testing;
