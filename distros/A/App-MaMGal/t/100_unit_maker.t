#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
package App::MaMGal::Unit::Maker::Base;
use strict;
use warnings;
use Carp;
use Carp 'verbose';
use base 'Test::Class';

use Test::More;
use Test::Exception;
use Test::Files;
use lib 'testlib';
use App::MaMGal::TestHelper;

sub _class_usage : Test(startup => 1) {
	use_ok('App::MaMGal::Maker') or $_[0]->BAILOUT("Class use failed");
}

sub creation_failures : Test(startup => 2) {
	dies_ok(sub { App::MaMGal::Maker->new },        "maker creation fails with no arg");
	dies_ok(sub { App::MaMGal::Maker->new('foo') }, "maker creation fails with something else than entry factory");
}

sub set_mock_entry
{
	my $self = shift;
	my $mock_entry = $self->{mock_entry} = get_mock_entry('App::MaMGal::Entry::Dir');
	return sub { $mock_entry };
}

sub instantiation : Test(setup => 2) {
	my $self = shift;
	my $mock_entry_sub = $self->set_mock_entry;
	my $ef_dir = $self->{ef_dir} = Test::MockObject->new->mock('create_entry_for', $mock_entry_sub);
	$ef_dir->set_isa('App::MaMGal::EntryFactory');
	my $maker;
	lives_ok(sub { $maker = App::MaMGal::Maker->new($ef_dir) }, "maker creation succeeds an entry factory arg");
	isa_ok($maker, 'App::MaMGal::Maker');
	$self->{maker} = $maker;
}

sub make_roots_dies_without_args : Test(2)
{
	my $self = shift;
	throws_ok { $self->{maker}->make_roots } qr{^Argument required\.$}, "maker dies on no args";
	throws_ok { $self->{maker}->make_without_roots } qr{^Argument required\.$}, "maker dies on no args";
}

package App::MaMGal::Unit::Maker::Normal;
use strict;
use warnings;
use Carp;
use Carp 'verbose';
use base 'App::MaMGal::Unit::Maker::Base';

use Test::More;
use Test::Exception;
use Test::Files;
use lib 'testlib';
use App::MaMGal::TestHelper;

sub make_without_roots_works : Test(5)
{
	my $self = shift;
	ok($self->{maker}->make_without_roots('some/thing'), "maker returns success on an empty dir");
	my ($method, $args) = $self->{ef_dir}->next_call;
	is($method, 'create_entry_for', 'create_entry_for called on the factory');
	is($args->[1], 'some/thing', 'correct path passed to the factory');
	ok(! $self->{mock_entry}->called('set_root'), 'root not set');
	ok(! $self->{mock_entry}->called('add_tools'), 'tools not set - factory does this');
}

sub make_roots_works : Test(5)
{
	my $self = shift;
	ok($self->{maker}->make_roots('some/thing'), "maker returns success on an empty dir");
	my ($method, $args) = $self->{ef_dir}->next_call;
	is($method, 'create_entry_for', 'create_entry_for called on the factory');
	is($args->[1], 'some/thing', 'correct path passed to the factory');
	$self->{mock_entry}->called_ok('set_root', 'root set');
	ok(! $self->{mock_entry}->called('add_tools'), 'tools not set - factory does this');
}

package App::MaMGal::Unit::Maker::NotADir;
use strict;
use warnings;
use Carp;
use Carp 'verbose';
use base 'App::MaMGal::Unit::Maker::Base';

use Test::More;
use Test::Exception;
use Test::Files;
use lib 'testlib';
use App::MaMGal::TestHelper;

sub set_mock_entry
{
	my $self = shift;
	my $mock_entry = $self->{mock_entry} = get_mock_entry('App::MaMGal::Entry::SomethinElse');
	return sub { $mock_entry };
}

sub make_roots_dies : Test(1)
{
	my $self = shift;
	throws_ok { $self->{maker}->make_roots('something/whatever') } qr{^%s: not a directory\.$}, "maker dies if thing returned by factory is not a dir object";
}

sub make_without_roots_dies : Test(1)
{
	my $self = shift;
	throws_ok { $self->{maker}->make_without_roots('something/whatever') } qr{^%s: not a directory\.$}, "maker dies if thing returned by factory is not a dir object";
}



package App::MaMGal::Unit::Maker::Crash;
use strict;
use warnings;
use Carp;
use Carp 'verbose';
use base 'App::MaMGal::Unit::Maker::Base';

use Test::More;
use Test::Exception;
use Test::Files;
use lib 'testlib';
use App::MaMGal::TestHelper;

sub set_mock_entry
{
	return sub { die 'dying here on purpose' };
}


sub make_roots_dies : Test(1)
{
	my $self = shift;
	throws_ok { $self->{maker}->make_roots('something/whatever') } qr{^dying here on purpose}, "maker dies if factory call crashes";
}

sub make_without_roots_dies : Test(1)
{
	my $self = shift;
	throws_ok { $self->{maker}->make_without_roots('something/whatever') } qr{^dying here on purpose}, "maker dies if factory call crashes";
}


package main;
use strict;
use warnings;
use Test::More;
unless (defined caller) {
	plan tests =>
		App::MaMGal::Unit::Maker::Normal->expected_tests +
		App::MaMGal::Unit::Maker::NotADir->expected_tests +
		App::MaMGal::Unit::Maker::Crash->expected_tests;
	App::MaMGal::Unit::Maker::Normal->runtests;
	App::MaMGal::Unit::Maker::NotADir->runtests;
	App::MaMGal::Unit::Maker::Crash->runtests;
}
1;

