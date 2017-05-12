#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
package App::MaMGal::Unit::ImageInfo;
use strict;
use warnings;
use Carp 'verbose';
use File::stat;
use Test::More;
use Test::Exception;
use Test::Warn;
use base 'Test::Class';

use lib 'testlib';
use App::MaMGal::TestHelper;

sub _dir_preparation : Test(startup) {
	prepare_test_data;
}

# This should be done in a BEGIN, but then planning the test count is difficult.
# However we are not using function prototypes, so it does not matter much.
sub _class_usage : Test(startup => 1) {
	use_ok('App::MaMGal::ImageInfoFactory') or $_[0]->BAILOUT("Class use failed");
}

sub creation_aborts : Test(startup => 6) {
	my $self = shift;
	dies_ok(sub { App::MaMGal::ImageInfoFactory->new },                           'new dies without args');
	dies_ok(sub { App::MaMGal::ImageInfoFactory->new('junk') },                   'new dies with a junk arg');
	dies_ok(sub { App::MaMGal::ImageInfoFactory->new(get_mock_datetime_parser) }, 'new dies without logger');
	dies_ok(sub { App::MaMGal::ImageInfoFactory->new(get_mock_datetime_parser, 'junk') }, 'new dies without logger');
	my $f = App::MaMGal::ImageInfoFactory->new(get_mock_datetime_parser, get_mock_logger);
	dies_ok(sub { $f->read },       'read dies without an arg');
	dies_ok(sub { $f->read('td') }, 'read dies with a non-picture');
}

sub creation : Test(setup => 2) {
	my $self = shift;
	my $mpp = $self->{injected_parser} = get_mock_datetime_parser;
	my $ml = $self->{injected_logger} = get_mock_logger;
	my $f = App::MaMGal::ImageInfoFactory->new($mpp, $ml);
	ok($f);
	isa_ok($f, 'App::MaMGal::ImageInfoFactory');
	$self->{jpg} = $f->read('td/varying_datetimes.jpg');
	$self->{jpg_no_0x9003} = $f->read('td/without_0x9003.jpg');
	$self->{jpg_no_0x9003_0x9004} = $f->read('td/without_0x9003_0x9004.jpg');
	$self->{jpg_no_0x9003_0x9004_0x0132} = $f->read('td/without_0x9003_0x9004_0x0132.jpg');
	$self->{png_nodesc} = $f->read('td/more/b.png');
	$self->{png_desc} = $f->read('td/more/a.png');
}

sub parser_injection : Test(6) {
	my $self = shift;
	my $mpp = $self->{injected_parser};
	is($self->{jpg}->{parser}, $mpp, 'parser was injected correctly by the factory');
	is($self->{jpg_no_0x9003}->{parser}, $mpp, 'parser was injected correctly by the factory');
	is($self->{jpg_no_0x9003_0x9004}->{parser}, $mpp, 'parser was injected correctly by the factory');
	is($self->{jpg_no_0x9003_0x9004_0x0132}->{parser}, $mpp, 'parser was injected correctly by the factory');
	is($self->{png_nodesc}->{parser}, $mpp, 'parser was injected correctly by the factory');
	is($self->{png_desc}->{parser}, $mpp, 'parser was injected correctly by the factory');
}

sub logger_injection : Test(6) {
	my $self = shift;
	my $logger = $self->{injected_logger};
	is($self->{jpg}->{logger}, $logger, 'logger was injected correctly by the factory');
	is($self->{jpg_no_0x9003}->{logger}, $logger, 'logger was injected correctly by the factory');
	is($self->{jpg_no_0x9003_0x9004}->{logger}, $logger, 'logger was injected correctly by the factory');
	is($self->{jpg_no_0x9003_0x9004_0x0132}->{logger}, $logger, 'logger was injected correctly by the factory');
	is($self->{png_nodesc}->{logger}, $logger, 'logger was injected correctly by the factory');
	is($self->{png_desc}->{logger}, $logger, 'logger was injected correctly by the factory');
}

sub description_method : Test(6) {
	my $self = shift;
	is($self->{jpg}->description, "A description of c.jpg\n", 'jpeg description is correct');
	is($self->{jpg_no_0x9003}->description, "A description of c.jpg\n", 'jpeg description is correct');
	is($self->{jpg_no_0x9003_0x9004}->description, "A description of c.jpg\n", 'jpeg description is correct');
	is($self->{jpg_no_0x9003_0x9004_0x0132}->description, "A description of c.jpg\n", 'jpeg description is correct');
	is($self->{png_desc}->description, "Test image A", 'png description is correct');
	is($self->{png_nodesc}->description, undef, 'png with no description returns undef');
}

sub exif_datetime_original_string : Test(4) {
	my $self = shift;
	is($self->{jpg}->datetime_original_string, '2008:11:27 20:43:53', 'returned datetime original is the exif field');
	is($self->{jpg_no_0x9003}->datetime_original_string, undef, 'returned datetime original is undefined');
	is($self->{jpg_no_0x9003_0x9004}->datetime_original_string, undef, 'returned datetime original is undefined');
	is($self->{jpg_no_0x9003_0x9004_0x0132}->datetime_original_string, undef, 'returned datetime original is undefined');
}

sub exif_datetime_digitized_string : Test(4) {
	my $self = shift;
	is($self->{jpg}->datetime_digitized_string, '2008:11:27 20:43:51', 'returned datetime digitized is the exif field');
	is($self->{jpg_no_0x9003}->datetime_digitized_string, '2008:11:27 20:43:51', 'returned datetime digitized is the exif field');
	is($self->{jpg_no_0x9003_0x9004}->datetime_digitized_string, undef, 'returned datetime digitized is undefined');
	is($self->{jpg_no_0x9003_0x9004_0x0132}->datetime_digitized_string, undef, 'returned datetime digitized is undefined');
}

sub exif_datetime_string : Test(4) {
	my $self = shift;
	is($self->{jpg}->datetime_string, '2008:11:27 20:43:52', 'returned datetime is the exif field');
	is($self->{jpg_no_0x9003}->datetime_string, '2008:11:27 20:43:52', 'returned datetime is the exif field');
	is($self->{jpg_no_0x9003_0x9004}->datetime_string, '2008:11:27 20:43:52', 'returned datetime is the exif field');
	is($self->{jpg_no_0x9003_0x9004_0x0132}->datetime_string, undef, 'returned datetime original is undefined');
}

sub creation_time_method : Test(4) {
	my $self = shift;
	my %parsers = (
		jpg                         => Test::MockObject->new->mock('parse', sub { 1231231231 }),
		jpg_no_0x9003               => Test::MockObject->new->mock('parse', sub { 1231231232 }),
		jpg_no_0x9003_0x9004        => Test::MockObject->new->mock('parse', sub { 1231231233 }),
		jpg_no_0x9003_0x9004_0x0132 => Test::MockObject->new->mock('parse', sub { undef }),
	);
	# inject parsers
	$self->{$_}->{parser} = $parsers{$_} for keys %parsers;

	is($self->{jpg}->creation_time, '1231231231', 'returned datetime is the mocked time');
	is($self->{jpg_no_0x9003}->creation_time, '1231231232', 'returned datetime is the mocked time');
	is($self->{jpg_no_0x9003_0x9004}->creation_time, '1231231233', 'returned datetime is the mocked time');
	is($self->{jpg_no_0x9003_0x9004_0x0132}->creation_time, undef, 'returned datetime original is undefined');
}

sub _test_creation_time {
	my $self = shift;
	my $file = shift;
	my $mp = $self->{$file}->{parser} = Test::MockObject->new;
	my $ml = $self->{$file}->{logger};
	my $parse_map = shift;
	my $expected_result = shift;
	my $expected_tag = shift;
	my $expected_warning = shift;
	my $expected_filename = shift;
	$mp->mock('parse', sub { exists $parse_map->{$_[1]} ? return &{$parse_map->{$_[1]}} : die "arg ".$_[1]." not found in map" });
	$ml->clear;
	my $level = $Test::Builder::Level;
	local $Test::Builder::Level = $level + 1;
	my $actual_result = $self->{$file}->creation_time;
	if ($expected_warning) {
		logged_only_ok($ml, $expected_warning, $expected_filename);
	} else {
		ok(! $ml->called('log_message'), 'log message was not called');
		ok(1, 'dummy test to keep test count constant');
		ok(1, 'dummy test to keep test count constant');
	}
	is($actual_result, $expected_result, "creation time returns parse value for $expected_tag");
}

sub when_all_tags_present_and_datetime_original_crashes_then_creation_time_returns_datetime_digitized: Test(5) {
	my $self = shift;
	my %parse_map = (
		'2008:11:27 20:43:51' => sub { 1234567891 },
		'2008:11:27 20:43:52' => sub { 1234567892 },
		'2008:11:27 20:43:53' => sub { die "parsing failed" },
	);
	$self->_test_creation_time('jpg', \%parse_map, 1234567891, 'datetime_digitized', qr{EXIF tag 0x9003: parsing failed}, 'td/varying_datetimes.jpg');
}

sub when_all_tags_present_and_parse_then_creation_time_returns_datetime_original: Test(4) {
	my $self = shift;
	my %parse_map = (
		'2008:11:27 20:43:51' => sub { 1234567891 },
		'2008:11:27 20:43:52' => sub { 1234567892 },
		'2008:11:27 20:43:53' => sub { 1234567893 },
	);
	$self->_test_creation_time('jpg', \%parse_map, 1234567893, 'datetime_original');
}

sub when_all_tags_present_and_just_datetime_original_does_not_parse_then_creation_time_returns_datetime_digitized : Test(4) {
	my $self = shift;
	my %parse_map = (
		'2008:11:27 20:43:51' => sub { 1234567891 },
		'2008:11:27 20:43:52' => sub { 1234567892 },
		'2008:11:27 20:43:53' => sub { undef },
	);
	$self->_test_creation_time('jpg', \%parse_map, 1234567891, 'datetime_digitized');
}

sub when_all_tags_present_and_just_datetime_parses_then_creation_time_returns_datetime : Test(4) {
	my $self = shift;
	my %parse_map = (
		'2008:11:27 20:43:51' => sub { undef },
		'2008:11:27 20:43:52' => sub { 1234567892 },
		'2008:11:27 20:43:53' => sub { undef },
	);
	$self->_test_creation_time('jpg', \%parse_map, 1234567892, 'datetime');
}

sub when_all_tags_present_and_none_parses_then_creation_time_returns_undef : Test(4) {
	my $self = shift;
	my %parse_map = (
		'2008:11:27 20:43:51' => sub { undef },
		'2008:11:27 20:43:52' => sub { undef },
		'2008:11:27 20:43:53' => sub { undef },
	);
	$self->_test_creation_time('jpg', \%parse_map, undef, 'undef');
}

sub when_datetime_original_tag_not_present_and_rest_parse_then_creation_time_returns_datetime_digitized : Test(4) {
	my $self = shift;
	my %parse_map = (
		'2008:11:27 20:43:51' => sub { 1234567891 },
		'2008:11:27 20:43:52' => sub { 1234567892 },
	);
	$self->_test_creation_time('jpg_no_0x9003', \%parse_map, 1234567891, 'datetime_digitized');
}

sub when_datetime_original_tag_not_present_and_just_datetime_parses_then_creation_time_returns_datetime_digitized : Test(4) {
	my $self = shift;
	my %parse_map = (
		'2008:11:27 20:43:51' => sub { undef },
		'2008:11:27 20:43:52' => sub { 1234567892 },
	);
	$self->_test_creation_time('jpg_no_0x9003', \%parse_map, 1234567892, 'datetime');
}

sub when_datetime_original_tag_not_present_and_none_parses_then_creation_time_returns_undef : Test(4) {
	my $self = shift;
	my %parse_map = (
		'2008:11:27 20:43:51' => sub { undef },
		'2008:11:27 20:43:52' => sub { undef },
	);
	$self->_test_creation_time('jpg_no_0x9003', \%parse_map, undef, 'undef');
}


sub when_just_datetime_tag_present_and_parses_then_creation_time_returns_datetime : Test(4) {
	my $self = shift;
	my %parse_map = (
		'2008:11:27 20:43:52' => sub { 1234567892 },
	);
	$self->_test_creation_time('jpg_no_0x9003_0x9004', \%parse_map, 1234567892, 'datetime');
}

sub when_just_datetime_tag_present_and_none_parses_then_creation_time_returns_undef : Test(4) {
	my $self = shift;
	my %parse_map = (
		'2008:11:27 20:43:52' => sub { undef },
	);
	$self->_test_creation_time('jpg_no_0x9003_0x9004', \%parse_map, undef, 'undef');
}


sub when_no_datetime_tag_present_then_creation_time_returns_undef : Test(4) {
	my $self = shift;
	$self->_test_creation_time('jpg_no_0x9003_0x9004_0x0132', {}, undef, 'undef');
}

package App::MaMGal::Unit::ImageInfo::ImageInfo;
use strict;
use warnings;
use Carp 'verbose';
use File::stat;
use Test::More;
use Test::Exception;
use Test::Warn;
use base 'App::MaMGal::Unit::ImageInfo';
use lib 'testlib';
use App::MaMGal::TestHelper;

use vars '%ENV';
$ENV{MAMGAL_FORCE_IMAGEINFO} = 'App::MaMGal::ImageInfo::ImageInfo';
App::MaMGal::Unit::ImageInfo::ImageInfo->runtests unless defined caller;

1;
