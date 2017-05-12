#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Carp 'verbose';
use Test::More tests => 69;
use Test::Exception;
use Test::HTML::Content;
use lib 'testlib';
use App::MaMGal::TestHelper;
use Image::Magick;

prepare_test_data;

use_ok('App::MaMGal::MplayerWrapper');

dies_ok(sub { App::MaMGal::MplayerWrapper::ExecutionFailureException->new }, 'exception creation dies without arguments');
dies_ok(sub { App::MaMGal::MplayerWrapper::ExecutionFailureException->new(message => 'foo bar', stderr => 'just one') }, 'exception creation dies with just one argument');
dies_ok(sub { App::MaMGal::MplayerWrapper::ExecutionFailureException->new(message => 'foo bar', stdout => 'just one') }, 'exception creation dies with just another arg');

sub exception_instantiation_ok
{
	my $level = $Test::Builder::Level;
	local $Test::Builder::Level = $level + 1;

	my $message = shift;
	my @args = @_;
	my $e;
	lives_ok(sub { $e = App::MaMGal::MplayerWrapper::ExecutionFailureException->new(@args) }, $message);
	ok($e);
	is($e->message, 'boom', 'message is OK');
	dies_ok(sub { $e->reason }, 'reason method does not exist');
	dies_ok(sub { $e->filename}, 'filename method does not exist');
	$e
}

my $e;
$e = exception_instantiation_ok('exception creation succeeds with unnamed argument', 'boom');
is($e->stdout, undef);
is($e->stderr, undef);
$e = exception_instantiation_ok('exception creation succeeds with message argument', message => 'boom');
is($e->stdout, undef);
is($e->stderr, undef);
$e = exception_instantiation_ok('exception creation succeeds without message', error => 'boom');
is($e->stdout, undef);
is($e->stderr, undef);
$e = exception_instantiation_ok('exception creation succeeds with all 3 args', message => 'boom', stdout => "1,2,3", stderr => "2,3,4");
is($e->stdout, "1,2,3");
is($e->stderr, "2,3,4");

dies_ok(sub { App::MaMGal::MplayerWrapper::NotAvailableException->new('something') }, 'this exception type does not accept a message arg');
dies_ok(sub { App::MaMGal::MplayerWrapper::NotAvailableException->new(message => 'something') }, 'this exception type does not accept a message arg');
dies_ok(sub { App::MaMGal::MplayerWrapper::NotAvailableException->new(error => 'something') }, 'this exception type does not accept a message arg');
$e = App::MaMGal::MplayerWrapper::NotAvailableException->new;
ok($e);
is($e->message, 'mplayer is not available - films will not be represented by snapshots.');

dies_ok(sub { App::MaMGal::MplayerWrapper->new },                    "wrapper can not be created without any arg");
dies_ok(sub { App::MaMGal::MplayerWrapper->new(1) },                 "wrapper can not be created with some junk parameter");

{
my $w;
my $mccy = get_mock_cc(1);
lives_ok(sub { $w = App::MaMGal::MplayerWrapper->new($mccy) },        "wrapper can be created with command checker");

my ($snap);
is($mccy->next_call, undef, 'checker not interrogated until fist wrapper use');
$mccy->clear;

dies_ok(sub { $w->snapshot() },				"wrapper cannot get a snapshot of undef");
my ($m, $args) = $mccy->next_call;
is($m, 'is_available', 'checker is interrogated on fist wrapper use');
is_deeply($args, [$mccy, 'mplayer'], 'checker is asked about mplayer');
$mccy->clear;

dies_ok(sub { $w->snapshot('td/notthere.mov') },	"wrapper cannot get a snapshot of an inexistant file");
is($mccy->next_call, undef, 'checker not interrogated more than once');
$mccy->clear;

throws_ok(sub { $snap = $w->snapshot('td/c.jpg') }, 'App::MaMGal::MplayerWrapper::ExecutionFailureException', "wrapper cannot survive snapshotting a non-film file");
my $err = $@;
is($mccy->next_call, undef, 'checker not interrogated more than once');
$mccy->clear;
ok($err->message, "invalid file produces some exception message");
ok($err->stdout, "invalid file produces some messages");
cmp_ok(scalar @{$err->stdout}, '>', 0, "there are lines in the stdout file");
is(scalar(grep(/\n$/, @{$err->stdout})), 0, "no newlines in the stdout file");
ok($err->stderr, "invalid file produces some error messages");
cmp_ok(scalar @{$err->stderr}, '>', 0, "there are lines in the stderr file");
is(scalar(grep(/\n$/, @{$err->stderr})), 0, "no newlines in the stderr file");

lives_ok(sub { $snap = $w->snapshot('td/one_film/m.mov') },	"wrapper can get a snapshot of a film file");
is($mccy->next_call, undef, 'checker not interrogated more than once');
$mccy->clear;
isa_ok($snap, 'Image::Magick',					"snapshot");
}

{
my $mccn = get_mock_cc(0);
my $w;
lives_ok(sub { $w = App::MaMGal::MplayerWrapper->new($mccn) },        "wrapper can be created with command checker");

is($mccn->next_call, undef, 'checker not interrogated until fist wrapper use');
$mccn->clear;

throws_ok(sub { $w->snapshot() }, 'App::MaMGal::MplayerWrapper::NotAvailableException', "failed because mplayer was not found");
my ($m, $args) = $mccn->next_call;
is($m, 'is_available', 'checker is interrogated on fist wrapper use');
is_deeply($args, [$mccn, 'mplayer'], 'checker is asked about mplayer');
$mccn->clear;

throws_ok(sub { $w->snapshot('td/notthere.mov') }, 'App::MaMGal::MplayerWrapper::NotAvailableException', "failed because mplayer was not found");
is($mccn->next_call, undef, 'checker not interrogated more than once');
$mccn->clear;

throws_ok(sub { $w->snapshot('td/c.jpg') }, 'App::MaMGal::MplayerWrapper::NotAvailableException', "failed because mplayer was not found");
is($mccn->next_call, undef, 'checker not interrogated more than once');
$mccn->clear;

throws_ok(sub { $w->snapshot('td/one_film/m.mov') }, 'App::MaMGal::MplayerWrapper::NotAvailableException', "failed because mplayer was not found");
is($mccn->next_call, undef, 'checker not interrogated more than once');
$mccn->clear;
}


