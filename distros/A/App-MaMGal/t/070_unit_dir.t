#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007-2010 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
package App::MaMGal::Unit::Entry::Dir;
use strict;
use warnings;
use Carp 'verbose';
use Test::More;
use Test::Exception;
use Test::Files;
use Test::HTML::Content;
use lib 'testlib';
BEGIN { our @ISA = 'App::MaMGal::Unit::Entry::NonPicture' }
BEGIN { do 't/060_unit_nonpicture.t' }

use App::MaMGal::TestHelper;
use File::stat;
use App::MaMGal::EntryFactory;
use App::MaMGal::ImageInfoFactory;

sub class_setting : Test(startup) {
	my $self = shift;
	$self->{class_name} = 'App::MaMGal::Entry::Dir';
}

sub unmocked_factories_for_dirs : Test(setup => 0) {
	my $self = shift;
	my $iif = App::MaMGal::ImageInfoFactory->new(get_mock_datetime_parser, get_mock_logger);
	{
		my $e = $self->{entry};
		$e->add_tools({
			entry_factory => App::MaMGal::EntryFactory->new(get_mock_formatter, get_mock_mplayer_wrapper, $iif, get_mock_logger),
			image_info_factory => $iif,
		});
	}
	{
		my $e = $self->{entry_no_stat};
		$e->add_tools({
			entry_factory => App::MaMGal::EntryFactory->new(get_mock_formatter, get_mock_mplayer_wrapper, $iif, get_mock_logger),
			image_info_factory => $iif,
		});
	}
}

sub container_method : Test(1) {
	# this is not mocked for Dir tests
	ok(1);
}

sub side_length_method : Test(10) {
	my $self = shift;
	my $e = $self->{entry};
	is($e->_side_length(1), 2);
	is($e->_side_length(2), 2);
	is($e->_side_length(3), 2);
	is($e->_side_length(4), 2);
	is($e->_side_length(5), 3);
	is($e->_side_length(9), 3);
	is($e->_side_length(10), 4);
	is($e->_side_length(35), 6);
	is($e->_side_length(36), 6);
	is($e->_side_length(37), 7);
}

sub page_path_method : Test(2) {
	my $self = shift;
	my $class_name = $self->{class_name};
	my @test_file_name = $self->file_name;
	{
		my $e = $self->{entry};
		is($e->page_path, $test_file_name[1].'/index.html', "$class_name page_path is correct");
	}
	{
		my $e = $self->{entry_no_stat};
		is($e->page_path, $test_file_name[1].'/index.html', "$class_name page_path is correct");
	}
}

sub thumbnail_path_method : Test(2) {
	my $self = shift;
	my $class_name = $self->{class_name};
	my @test_file_name = $self->file_name;
	{
		my $e = $self->{entry};
		is($e->thumbnail_path, $test_file_name[1].'/.mamgal-index.png', "$class_name thumbnail_path is correct");
	}
	{
		my $e = $self->{entry_no_stat};
		is($e->thumbnail_path, $test_file_name[1].'/.mamgal-index.png', "$class_name thumbnail_path is correct");
	}
}

sub invalid_make_invocation : Test {
	my $self = shift;
	dies_ok(sub { $self->{entry}->make }, "Dir dies on make invocation with no arg");
}

sub empty_creation_time_range_test {
	my $self = shift;
	my $d = $self->{entry};
	my $single_creation_time = $d->creation_time;
	ok($single_creation_time, "There is some non-zero create time");
	my @creation_time_range = $d->creation_time;
	is(scalar @creation_time_range, 1, "Creation time range is empty");
	is($creation_time_range[0], $single_creation_time, "Range-type creation time is equal to the scalar one");
}

# It's difficult to test these two without introducing dependencies on other
# classes, so we test these in integration tests.
sub is_intetresting_method : Test(1) { ok(1); }
sub tile_path_method : Test(1) { ok(1); }

package App::MaMGal::Unit::Entry::Dir::Empty;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Files;
use Test::HTML::Content;
use lib 'testlib';
BEGIN { our @ISA = 'App::MaMGal::Unit::Entry::Dir' }

use App::MaMGal::TestHelper;
use File::stat;

sub class_setting : Test(startup) {
	my $self = shift;
	$self->SUPER::class_setting;
	$self->{test_file_name} = [qw(td empty)];
}

sub empty_dir_properties : Test(3) {
	my $self = shift;
	my $d = $self->{entry};
	ok(! $d->is_root,                           "Freshly created dir is not a root");
	dies_ok(sub { $d->neighbours_of_index(0) }, "No neighbours of first index in an empty dir, because there is no such index");
	dies_ok(sub { $d->neighbours_of_index(1) }, "No neighbours of second index in an empty dir, because there is no such index");
}

sub zz_empty_dir : Test(startup => 1) {
	dir_only_contains_ok('td/empty', [],                         "Directory is empty initially");
}

sub valid_make_invocation : Test(5) {
	my $self = shift;
	my $d = $self->{entry};
	my $mf = get_mock_formatter(qw(format stylesheet));
	$d->add_tools({formatter => $mf});
	lives_ok(sub { $d->make },                                   "Dir lives on make invocation");
	ok($mf->called('format'),                                    "Dir->make calls formatter->format internally");
	if ($d->is_root) {
		ok($mf->called('stylesheet'),                        "Dir->make calls formatter->stylesheet internally");
		dir_only_contains_ok('td/empty', [qw{index.html .mamgal-index.png .mamgal-style.css}],
                                                                     "Directory contains only the index file, thumb and stylesheet afterwards");
	} else {
		ok(1,                                                "Keep the number of tests constant.");
		dir_only_contains_ok('td/empty', [qw{index.html .mamgal-index.png}],
                                                                     "Directory contains only the index file and thumb afterwards");
	}
	use Text::Diff::Table; # work around a warning from UNIVERSAL::can
	file_ok('td/empty/index.html', "whatever",                   "Dir->make creates an index file");
}

sub creation_time_range : Test(3) {
	my $self = shift;
	# one-element range for empty dirss
	$self->empty_creation_time_range_test;
}

package App::MaMGal::Unit::Entry::Dir::MoreSubdir;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Files;
use Test::HTML::Content;
use lib 'testlib';
BEGIN { our @ISA = 'App::MaMGal::Unit::Entry::Dir' }

use App::MaMGal::TestHelper;
use File::stat;

sub class_setting : Test(startup) {
	my $self = shift;
	$self->SUPER::class_setting;
	$self->{test_file_name} = [qw(td/more subdir)];
}

sub more_subdir_tests : Test(3) {
	my $self = shift;
	# test root and containers on a deeply nested dir
	my $deep_dir = $self->{entry};
	ok(! $deep_dir->is_root,                                           "Freshly created dir is not a root");
	is_deeply([map { $_->name } $deep_dir->containers], [qw(td more)], "Non-root directory has some container names, in correct order");
	is(scalar($deep_dir->elements), 4,                                 "td/more/subdir has 4 elements - lost+found is ignored");
}

sub creation_time_range : Test(2) {
	my $self = shift;
	my $d = $self->{entry};
	my $single_creation_time = $d->creation_time;
	ok($single_creation_time, "There is some non-zero create time");
	my @creation_time_range = $d->creation_time;
	is(scalar @creation_time_range, 2, "Creation time range is non-empty");
}

sub is_intetresting_method : Test(1) {
	my $self = shift;
	my $e = $self->{entry};
	ok($e->is_interesting, "a dir with pictures in it is interesting");
}

# We cannot run these, as the general condition for Entry does not hold for non-empty dirs
# Instead we test this in the integration tests
sub stat_functionality : Test { ok(1) }
sub stat_functionality_when_created_without_stat : Test { ok(1) }

package App::MaMGal::Unit::Entry::Dir::ARootDir;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Files;
use Test::HTML::Content;
use lib 'testlib';
BEGIN { our @ISA = 'App::MaMGal::Unit::Entry::Dir' }

use App::MaMGal::TestHelper;
use File::stat;

sub class_setting : Test(startup) {
	my $self = shift;
	$self->SUPER::class_setting;
	$self->{test_file_name} = [qw(td root_dir)];
}

sub root_dir_tests : Test(2) {
	my $self = shift;
	# test root property on a dir already tagged as root
	my $rd = $self->{entry};
	ok($rd->is_root,                   "Freshly created root dir is root");
	is_deeply([($rd->containers)], [], "Root directory has no container names");
}

sub creation_time_range : Test(3) {
	my $self = shift;
	# one-element range for empty dirss
	$self->empty_creation_time_range_test;
}

# We cannot run these, as the general condition for Entry does not hold for non-empty dirs
# Instead we test this in the integration tests
sub stat_functionality : Test { ok(1) }
sub stat_functionality_when_created_without_stat : Test { ok(1) }

package App::MaMGal::Unit::Entry::Dir::Bin;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Files;
use Test::HTML::Content;
use lib 'testlib';
BEGIN { our @ISA = 'App::MaMGal::Unit::Entry::Dir' }

use App::MaMGal::TestHelper;
use File::stat;

sub class_setting : Test(startup) {
	my $self = shift;
	$self->SUPER::class_setting;
	$self->{test_file_name} = [qw(/ bin)];
}

sub slash_bin_tests : Test(2) {
	my $self = shift;
	# test root properties on a absolutely referenced subdir of a root dir and its container
	my $bd = $self->{entry};
	ok(! $bd->is_root,          "Freshly created dir is not a root");
	ok($bd->container->is_root, "Toplevel dir's container is root");
}

# We cannot run these, as the general condition for Entry does not hold for non-empty dirs
# Instead we test this in the integration tests
sub stat_functionality : Test { ok(1) }
sub stat_functionality_when_created_without_stat : Test { ok(1) }
sub is_intetresting_method : Test(1) { ok(1) }

package App::MaMGal::Unit::Entry::Dir::Slash;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Files;
use Test::HTML::Content;
use lib 'testlib';
BEGIN { our @ISA = 'App::MaMGal::Unit::Entry::Dir' }

use App::MaMGal::TestHelper;
use File::stat;

sub class_setting : Test(startup) {
	my $self = shift;
	$self->SUPER::class_setting;
	$self->{test_file_name} = [qw(/ .)];
}

sub slash_tests : Test {
	my $self = shift;
	# test root property on the real "/" root
	my $Rd = $self->{entry};
	ok($Rd->is_root, "Freshly created root dir is root");
}

sub name_method : Test(2) {
	my $self = shift;
	my $class_name = $self->{class_name};
	my @test_file_name = $self->file_name;
	{
		my $e = $self->{entry};
		is($e->name, '/', "$class_name name is correct");
	}
	{
		my $e = $self->{entry_no_stat};
		is($e->name, '/', "$class_name name is correct");
	}
}

sub page_path_method : Test(2) {
	my $self = shift;
	my $class_name = $self->{class_name};
	my @test_file_name = $self->file_name;
	{
		my $e = $self->{entry};
		is($e->page_path, '//index.html', "$class_name page_path is correct");
	}
	{
		my $e = $self->{entry_no_stat};
		is($e->page_path, '//index.html', "$class_name page_path is correct");
	}
}

sub thumbnail_path_method : Test(2) {
	my $self = shift;
	my $class_name = $self->{class_name};
	my @test_file_name = $self->file_name;
	{
		my $e = $self->{entry};
		is($e->thumbnail_path, '//.mamgal-index.png', "$class_name thumbnail_path is correct");
	}
	{
		my $e = $self->{entry_no_stat};
		is($e->thumbnail_path, '//.mamgal-index.png', "$class_name thumbnail_path is correct");
	}
}

# We cannot run these, as the general condition for Entry does not hold for non-empty dirs
# Instead we test this in the integration tests
sub stat_functionality : Test { ok(1) }
sub stat_functionality_when_created_without_stat : Test { ok(1) }
sub is_intetresting_method : Test(1) { ok(1) }

package App::MaMGal::Unit::Entry::Dir::Dot;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Files;
use Test::HTML::Content;
use lib 'testlib';
BEGIN { our @ISA = 'App::MaMGal::Unit::Entry::Dir' }

use App::MaMGal::TestHelper;
use File::stat;

sub class_setting : Test(startup) {
	my $self = shift;
	$self->SUPER::class_setting;
	$self->{test_file_name} = [qw(. .)];
}

sub dot_dir_tests : Test(1) {
	my $self = shift;
	# test creation of the current directory
	my $cd = $self->{entry};
	ok(! $cd->is_root, "Freshly created root dir is not a root");
}

# We cannot run these, as the general condition for Entry does not hold for non-empty dirs
# Instead we test this in the integration tests
sub stat_functionality : Test { ok(1) }
sub stat_functionality_when_created_without_stat : Test { ok(1) }
sub is_intetresting_method : Test(1) { ok(1) }

package main;
use Test::More;
unless (defined caller) {
	my @classes = map { 'App::MaMGal::Unit::Entry::Dir::'.$_ } qw(MoreSubdir Empty ARootDir Bin Slash Dot);
	my $tests = 0;
	$tests += $_->expected_tests foreach @classes;
	plan tests => $tests;
	# diag("About to test $_"), uncomment for debugging
	$_->runtests foreach @classes;
}

