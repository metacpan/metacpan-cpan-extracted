#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
package App::MaMGal::Unit::Entry::BrokenSymlink;
use strict;
use warnings;
use Carp 'verbose';
use Test::More;
use lib 'testlib';
BEGIN { our @ISA = 'App::MaMGal::Unit::Entry::NonPicture' }
BEGIN { do 't/060_unit_nonpicture.t' }

sub class_setting : Test(startup) {
	my $self = shift;
	$self->{class_name} = 'App::MaMGal::Entry::BrokenSymlink';
	$self->{test_file_name} = [qw(td symlink_broken)];
}

sub stat_functionality : Test {
	my $self = shift;
	my $e = $self->{entry_no_stat};

	my $ct = $e->creation_time;
	is($ct, undef, "Returned creation time is undefined");
	# don't try to touch a broken symlink
}

sub stat_functionality_when_created_without_stat : Test {
	my $self = shift;
	my $e = $self->{entry_no_stat};

	my $ct = $e->creation_time;
	is($ct, undef, "Returned creation time is undefined");
	# don't try to touch a broken symlink
}

# TODO: do it in integration tests
##lives_ok(sub { App::MaMGal::Formatter->new->entry_cell($n) },                 "BrokenSymlink can be interrogated as an entry cell target");

App::MaMGal::Unit::Entry::BrokenSymlink->runtests unless defined caller;
1;
