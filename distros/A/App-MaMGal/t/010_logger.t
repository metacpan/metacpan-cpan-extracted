#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007-2009 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
package App::MaMGal::Unit::Logger;
use strict;
use warnings;
use Carp 'verbose';
use Test::More;
use Test::Exception;
use Test::Warn;
use base 'Test::Class';

use lib 'testlib';
use App::MaMGal::TestHelper;

sub class_load : Test(startup => 1) {
	use_ok('App::MaMGal::Logger');
}

sub creation_fails_without_fh : Test(startup => 1) {
	dies_ok(sub { App::MaMGal::Logger->new }, 'creation dies without an arg');
}

sub instantiation : Test(setup => 1) {
	my $self = shift;
	$self->{mock_fh} = get_mock_fh;
	$self->{l} = App::MaMGal::Logger->new($self->{mock_fh});
	ok($self->{l});
}

sub log_message_method : Test(10) {
	my $self = shift;
	my $msg = 'bugga bugga buga!';
	my $prefix = 'wooow';
	warnings_are { $self->{l}->log_message($msg) } [], "log_message causes no warnings";
	printed_only_ok($self->{mock_fh}, qr{^\Q$msg\E$});# 'log_message causes a warning';
	$self->{mock_fh}->clear;
	warnings_are { $self->{l}->log_message($msg, $prefix) } [], "log_message causes no warnings";
	printed_only_ok($self->{mock_fh}, qr{^\Q$prefix: $msg\E$});# 'log_message causes a warning with prefix prepended correctly
}

sub log_other_exception : Tests(20)
{
	my $self = shift;
	my $e = get_mock_exception 'App::MaMGal::MplayerWrapper::OtherException';
	warnings_are { $self->{l}->log_exception($e) } [], 'log_exception causes no warnings';
	printed_only_ok($self->{mock_fh}, qr{^foo bar$});# log_exception prints a message first time
	$self->{mock_fh}->clear;
	warnings_are { $self->{l}->log_exception($e) } [], 'log_exception causes no warnings second time either';
	printed_only_ok($self->{mock_fh}, qr{^foo bar$});# log_exception prints a message even second time
	$self->{mock_fh}->clear;

	warnings_are { $self->{l}->log_exception($e, 'prefix') } [], 'log_message with prefix causes no warnings';
	printed_only_ok($self->{mock_fh}, qr{^prefix: foo bar$});# log_message with prefix prints a message first time
	$self->{mock_fh}->clear;
	warnings_are { $self->{l}->log_exception($e, 'prefix') } [], 'log_message with prefix causes no warnings second time either';
	printed_only_ok($self->{mock_fh}, qr{^prefix: foo bar$});# log_message with prefix prints a message even second time
}

sub log_not_available_exception : Tests(7)
{
	my $self = shift;
	my $e = get_mock_exception 'App::MaMGal::MplayerWrapper::NotAvailableException';
	warnings_are { $self->{l}->log_exception($e, 'prefix') } [], 'log_exception with prefix causes no warnings';
	printed_only_ok($self->{mock_fh}, qr{^prefix: foo bar$});# log_exception with prefix prints a message first time
	$self->{mock_fh}->clear;
	warnings_are { $self->{l}->log_exception($e, 'prefix') } [], 'log_exception with prefix causes no warnings second time either';
	is($self->{mock_fh}->next_call, undef, 'reading image without an mplayer on the second time prints no message');
}

sub log_system_exception : Test(10)
{
	my $self = shift;
	my $e = get_mock_exception 'App::MaMGal::SystemException';
	warnings_are { $self->{l}->log_exception($e) } [], 'log_exception causes no warnings';
	printed_only_ok($self->{mock_fh}, qr{^foo bar baz$});# log_exception prints an interpolated message first time
	$self->{mock_fh}->clear;
	warnings_are { $self->{l}->log_exception($e) } [], 'log_exception causes no warnings second time either';
	printed_only_ok($self->{mock_fh}, qr{^foo bar baz$});# log_exception prints an interpolated message second time too
}

sub log_execution_failure_exception : Test(42)
{
	my $self = shift;
	my $e_msgonly = get_mock_exception 'App::MaMGal::MplayerWrapper::ExecutionFailureException';
	$e_msgonly->mock('stdout');
	$e_msgonly->mock('stderr');
	warnings_are { $self->{l}->log_exception($e_msgonly, 'prefix') } [], 'log_exception with prefix causes no warnings';
	printed_only_ok($self->{mock_fh}, qr{^prefix: foo bar$});# log_exception with prefix prints the message without stderr/out if there are none
	$self->{mock_fh}->clear;

	my $e = get_mock_exception 'App::MaMGal::MplayerWrapper::ExecutionFailureException';
	$e->mock('stdout', sub { [qw{bim bam bom}] });
	$e->mock('stderr', sub { [qw{pim pam pom}] });
	# printing one without stderr/out does not affect the suppression
	warnings_are { $self->{l}->log_exception($e, 'prefix') } [], 'log_exception with prefix causes no warnings';
	printed_only_ok($self->{mock_fh}, [qr{^prefix: foo bar$}, qr{^prefix: ---.*standard output messages}, qr{^prefix: bim$}, qr{^prefix: bam$}, qr{^prefix: bom$}, qr{^prefix: ---.*standard error messages}, qr{^prefix: pim$}, qr{^prefix: pam$}, qr{^prefix: pom$}, qr{^prefix: ------}]);# log_exception with prefix prints the message and stderr/out first time
	$self->{mock_fh}->clear;

	warnings_are { $self->{l}->log_exception($e, 'prefix') } [], 'log_exception with prefix causes no warnings second time either';
	printed_only_ok($self->{mock_fh}, qr{^prefix: foo bar$});# log_exception with prefix prints just a message second time
}

App::MaMGal::Unit::Logger->runtests unless defined caller;
1;
