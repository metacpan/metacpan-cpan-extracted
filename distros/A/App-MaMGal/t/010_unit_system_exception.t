#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007-2009 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Carp 'verbose';
use Test::More tests => 14;
use Test::Exception;
use lib 'testlib';
use App::MaMGal::TestHelper;

use_ok('App::MaMGal::Exceptions');

dies_ok(sub { App::MaMGal::SystemException->new }, 'exception creation dies without arguments');

sub exception_instantiation_ok
{
	my $level = $Test::Builder::Level;
	local $Test::Builder::Level = $level + 1;

	my $instantiation_message = shift;
	my $message = shift;
	my @args = @_;
	my $e;
	lives_ok(sub { $e = App::MaMGal::SystemException->new(@args) }, $instantiation_message);
	ok($e);
	is($e->message, $message, 'message is OK');
	$e
}

my $e;
$e = exception_instantiation_ok('exception creation succeeds with unnamed argument and no placeholders', 'boom', 'boom');
is($e->interpolated_message, 'boom');

dies_ok(sub { App::MaMGal::SystemException->new('boom %s boom') }, 'exception creation dies with unnamed argument containing a placeholder');
dies_ok(sub { App::MaMGal::SystemException->new(message => 'boom %s %s boom', objects => [qw(asdf)]) }, 'exception creation dies with message containing more placeholders than there are objects');
dies_ok(sub { App::MaMGal::SystemException->new(message => 'boom %s boom', objects => [qw(asdf ghjk)]) }, 'exception creation dies with message containing less placeholders than there are objects');
dies_ok(sub { App::MaMGal::SystemException->new(message => 'boom %% boom', objects => [qw(asdf ghjk)]) }, 'exception creation dies with message containing a single quoted percent character and two objects passed');

$e = exception_instantiation_ok('exception creation succeeds with unnamed argument and no placeholders', 'bim %s bom', message => 'bim %s bom', objects => ['bam']);
is($e->interpolated_message, 'bim bam bom');

