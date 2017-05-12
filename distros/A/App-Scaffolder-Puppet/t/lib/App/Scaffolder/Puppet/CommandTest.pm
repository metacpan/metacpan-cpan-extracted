package App::Scaffolder::Puppet::CommandTest;
use parent qw(App::Scaffolder::Puppet::TestBase);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;
use File::Spec::Functions qw(catdir);
use App::Scaffolder::Puppet::Command;

sub get_extra_template_dirs_test : Test(2) {
	my ($self) = @_;

	my $sharedir = Path::Class::Dir->new(qw(share));
	my $cmd = App::Scaffolder::Puppet::Command->new({});
	local $ENV{SCAFFOLDER_TEMPLATE_PATH} = $sharedir->stringify();
	my @template_dirs = $cmd->get_extra_template_dirs('puppetmodule');
	cmp_ok(scalar @template_dirs, '>=', 1, 'at least one template dir found');
	is(
		scalar(grep { $_ eq $sharedir->subdir('puppetmodule')->stringify() } @template_dirs),
		1,
		'path from environment respected'
	);
}


sub get_target_test : Test(3) {
	my ($self) = @_;

	my $cmd = App::Scaffolder::Puppet::Command->new({});

	$self->{name_opt} = 'foo';
	is($cmd->get_target($self->{opt_mock}), 'foo', 'target ok');

	$self->{name_opt} = 'foo::bar';
	is($cmd->get_target($self->{opt_mock}), '.', 'target ok');

	$self->{target_opt} = catdir('test', 'dir');
	is(
		$cmd->get_target($self->{opt_mock}),
		catdir('test', 'dir'),
		'target parameter overrides'
	);
}


sub get_variables_test : Test(3) {
	my ($self) = @_;

	my $cmd = App::Scaffolder::Puppet::Command->new({});

	$self->{name_opt} = 'foo';
	is_deeply($cmd->get_variables($self->{opt_mock}), {
		name               => 'foo',
		package            => 'foo',
		nameparts          => ['foo'],
		namepartsjoined    => 'foo',
		namepartspath      => 'foo',
		subnameparts       => [],
		subnamepartsjoined => '',
		subnamepartspath   => '',
	}, 'variables ok');

	$self->{name_opt} = 'foo::bar';
	is_deeply($cmd->get_variables($self->{opt_mock}), {
		name               => 'foo::bar',
		package            => 'foo::bar',
		nameparts          => ['foo', 'bar'],
		namepartsjoined    => 'foo_bar',
		namepartspath      => catdir('foo', 'bar'),
		subnameparts       => ['bar'],
		subnamepartsjoined => 'bar',
		subnamepartspath   => 'bar',
	}, 'variables ok');

	$self->{name_opt} = 'foo::bar::baz';
	$self->{package_opt} = 'foo-bar-baz';
	is_deeply($cmd->get_variables($self->{opt_mock}), {
		name               => 'foo::bar::baz',
		package            => 'foo-bar-baz',
		nameparts          => ['foo', 'bar', 'baz'],
		namepartsjoined    => 'foo_bar_baz',
		namepartspath      => catdir('foo', 'bar', 'baz'),
		subnameparts       => ['bar', 'baz'],
		subnamepartsjoined => 'bar_baz',
		subnamepartspath   => catdir('bar', 'baz'),
	}, 'variables ok');
}


1;
