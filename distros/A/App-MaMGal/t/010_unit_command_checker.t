#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007-2009 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
package App::MaMGal::Unit::CommandChecker;
use strict;
use warnings;
use Carp 'verbose';
use Test::More;
use Test::Exception;
use base 'Test::Class';

use lib 'testlib';
use App::MaMGal::TestHelper;

sub class_load : Test(startup => 1) {
	use_ok('App::MaMGal::CommandChecker');
}

sub checker_creation : Test(setup => 1) {
	my $self = shift;
	ok($self->{c} = App::MaMGal::CommandChecker->new);
}

sub check_failures : Test(2) {
	my $self = shift;
	dies_ok(sub { $self->{c}->is_available } , 'must be run with an arg');
	dies_ok(sub { $self->{c}->is_available(qw(true false)) } , 'must be run with one arg');
}

sub check_true : Test(1) {
	my $self = shift;
	ok($self->{c}->is_available('true'), '/bin/true should always be there');
}

sub check_false : Test(1) {
	my $self = shift;
	ok($self->{c}->is_available('false'), '/bin/false should always be there');
}

sub check_inexistent : Test(1) {
	my $self = shift;
	ok(! $self->{c}->is_available('something_that_cannot_be_available'), 'an uninstalled command is not available');
}

App::MaMGal::Unit::CommandChecker->runtests unless defined caller;
1;
