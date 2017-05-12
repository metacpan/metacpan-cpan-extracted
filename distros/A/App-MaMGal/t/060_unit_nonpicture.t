#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
package App::MaMGal::Unit::Entry::NonPicture;
use strict;
use warnings;
use Carp 'verbose';
use Test::More;
use lib 'testlib';
BEGIN { our @ISA = 'App::MaMGal::Unit::Entry' }
BEGIN { do 't/050_unit_entry.t' }

sub class_setting : Test(startup) {
	my $self = shift;
	$self->{class_name} = 'App::MaMGal::Entry::NonPicture';
	$self->{test_file_name} = [qw(td empty_file)];
}

sub page_path_method : Test(2) {
	my $self = shift;
	my $class_name = $self->{class_name};
	my @test_file_name = $self->file_name;
	{
		my $e = $self->{entry};
		is($e->page_path, $test_file_name[1], "$class_name page_path is correct");
	}
	{
		my $e = $self->{entry_no_stat};
		is($e->page_path, $test_file_name[1], "$class_name page_path is correct");
	}
}

sub thumbnail_path_method : Test(2) {
	my $self = shift;
	my $class_name = $self->{class_name};
	{
		my $e = $self->{entry};
		is($e->thumbnail_path, undef, "$class_name thumbnail_path is correct");
	}
	{
		my $e = $self->{entry_no_stat};
		is($e->thumbnail_path, undef, "$class_name thumbnail_path is correct");
	}
}

# TODO: do it in integration tests
##lives_ok(sub { App::MaMGal::Formatter->new->entry_cell($n) },                 "NonPicture can be interrogated as an entry cell target");

App::MaMGal::Unit::Entry::NonPicture->runtests unless defined caller;
1;
