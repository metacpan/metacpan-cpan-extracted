package App::Puppet::Environment::UpdaterTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;
use App::Puppet::Environment::Updater;
use Directory::Scratch;
use Log::Dispatchouli;
use Git::Wrapper;

sub setup : Test(setup) {
	my ($self) = @_;

	$self->{test_logger} = Log::Dispatchouli->new_tester();
	$self->{tmp} = Directory::Scratch->new();

	my $repos_dir = $self->{tmp}->mkdir('repos');
	my $env = $repos_dir->subdir('environment');
	$env->mkpath();
	$self->{env_git} = Git::Wrapper->new($env);
	$self->{env_git}->init();
	$self->{env_git}->config('user.email' => 'test@example.com');
	$self->{env_git}->config('user.name'  => 'test@example.com');
	$self->{tmp}->create_tree({
		'repos/environment/site.pp' => "node example.com {}",
	});
	$self->{env_git}->add('.');
	$self->{env_git}->commit('-m', 'first commit');
	$self->{env_git}->branch('foo');

	$self->{workdir} = $self->{tmp}->mkdir('work');
	$self->{work_git} = Git::Wrapper->new($self->{workdir});
	$self->{work_git}->clone($env, $self->{workdir});
	$self->{work_git}->config('user.email' => 'test@example.com');
	$self->{work_git}->config('user.name'  => 'test@example.com');
}

sub teardown : Test(teardown) {
	my ($self) = @_;

	undef $self->{tmp};
}

sub test_new : Test(1) {
	my ($self) = @_;

	new_ok('App::Puppet::Environment::Updater' => [
		environment => 'testing',
		from        => 'development',
	], 'instance created');
}


sub remote_branch_for_test : Test(2) {
	my ($self) = @_;

	my $branch = $self->create_updater()->remote_branch_for('bar');
	is($branch, 'origin/bar', 'remote branch name constructed');

	$branch = $self->create_updater(
		remote => 'github',
	)->remote_branch_for('bar');
	is($branch, 'github/bar', 'remote can be set in constructor');
}


sub create_and_switch_to_branch_test : Test(1) {
	my ($self) = @_;

	my $app = $self->create_updater();
	$app->create_and_switch_to_branch('foo');
	is_deeply(
		[ '* foo', '  master' ],
		[ $self->{work_git}->branch() ],
		'branch created'
	);
}


sub update_branch_test : Test(3) {
	my ($self) = @_;

	my $app = $self->create_updater();
	$app->update_branch('master');
	is(
		($self->{work_git}->show())[0],
		($self->{env_git}->show())[0],
		'up to date before commit on upstream master'
	);

	$self->{tmp}->create_tree({
		'repos/environment/site.pp' => "node 'example.com' {}",
	});
	$self->{env_git}->commit('-a', '-m', 'Add single quotes');
	isnt(
		($self->{env_git}->show())[0],
		($self->{work_git}->show())[0],
		'not up to date after commit on upstream'
	);

	$app->get_git()->fetch('origin');
	$app->update_branch('master');
	is(
		($self->{env_git}->show())[0],
		($self->{work_git}->show())[0],
		'up to date after update'
	);
}


sub merge_test : Test(1) {
	my ($self) = @_;

	$self->{tmp}->create_tree({
		'repos/environment/site.pp' => "node 'example.com' {}",
	});
	$self->{env_git}->commit('-a', '-m', 'Add single quotes');

	my $app = $self->create_updater();
	$app->create_and_switch_to_branch('foo');
	$app->get_git()->fetch('origin');
	$app->update_branch('master');

	$app->merge('master', 'foo');
	like(
		($self->{work_git}->log('foo'))[0]->{message},
		qr{master.*foo},
		'branch merged, merge commit created'
	);
}


sub run_test : Test(1) {
	my ($self) = @_;

	$self->{env_git}->branch('testing');
	$self->{tmp}->create_tree({
		'repos/environment/site.pp' => "node 'example.com' {}",
	});
	$self->{env_git}->commit('-a', '-m', 'Add single quotes');
	$self->{env_git}->branch('development');
	$self->{work_git}->checkout('-b', 'testing', 'origin/foo');
	my $updater = $self->create_updater();
	$updater->run();
	my @log = $self->{work_git}->log();
	like(
		$log[0]->message(),
		qr{Merge branch 'development' into testing},
		'development merged into testing'
	);
}


sub get_local_branches_test : Test(2) {
	my ($self) = @_;

	my $updater = $self->create_updater();
	my @local_branches = $updater->get_local_branches();
	is_deeply(\@local_branches, ['master'], 'only master is local');
	$updater->get_git()->branch('foo');
	is_deeply(
		[sort $updater->get_local_branches()],
		['foo', 'master'],
		'foo exists'
	);
}


sub create_updater {
	my ($self, %arg) = @_;

	return App::Puppet::Environment::Updater->new({
		environment => 'testing',
		from        => 'development',
		workdir     => $self->{workdir},
		logger      => $self->{test_logger},
		%arg,
	})
}


1;
