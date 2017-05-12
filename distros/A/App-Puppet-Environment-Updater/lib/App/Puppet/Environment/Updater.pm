package App::Puppet::Environment::Updater;
{
  $App::Puppet::Environment::Updater::VERSION = '0.001001';
}

# ABSTRACT: Update a Puppet environment in a Git branch

use Moose;
use MooseX::FollowPBP;

with 'MooseX::Getopt';

use Carp;
use Git::Wrapper;
use File::pushd;
use Path::Class::Dir;
use MooseX::Types::Path::Class;
use Log::Dispatchouli;
use List::MoreUtils qw(any);
use Term::ANSIColor qw(:constants);
use Try::Tiny;
use namespace::autoclean;


has 'from' => (
	is            => 'ro',
	isa           => 'Str',
	required      => 1,
	documentation => 'Environment/branch which should be merged',
);

has 'environment' => (
	is            => 'ro',
	isa           => 'Str',
	required      => 1,
	documentation => 'Environment/branch which should be updated',
);

has 'remote' => (
	is            => 'ro',
	isa           => 'Str',
	documentation => 'Git remote to fetch latest changes from, defaults to "origin"',
	default       => 'origin',
);

has 'workdir' => (
	is            => 'ro',
	isa           => 'Path::Class::Dir',
	coerce        => 1,
	documentation => 'Directory to work in, should be the directory with the environment that should be updated',
	default       => sub {
		return Path::Class::Dir->new('.')->absolute();
	},
);

has 'git' => (
	is      => 'ro',
	isa     => 'Git::Wrapper',
	traits  => ['NoGetopt'],
	lazy    => 1,
	default => sub {
		my ($self) = @_;
		return Git::Wrapper->new(
			$self->get_workdir()->absolute()->resolve()->stringify()
		);
	},
);

has 'logger' => (
	is       => 'ro',
	isa      => 'Log::Dispatchouli',
	traits   => ['NoGetopt'],
	lazy     => 1,
	default  => sub {
		my ($self) = @_;
		my $logger = Log::Dispatchouli->new({
			ident     => 'environment-updater',
			to_stderr => 1,
			log_pid   => 0,
		});
		$logger->set_prefix('[update-'.$self->get_environment().'] ');
		return $logger;
	},
);



sub get_proxy_logger {
	my ($self, $prefix) = @_;

	return $self->get_logger()->proxy({
		proxy_prefix => $prefix,
	});
}



sub run {
	my ($self) = @_;

	if ($self->get_git()->status()->is_dirty()) {
		$self->get_logger()->log_fatal(BOLD.RED."Dirty sandbox, aborting".RESET);
	}

	try {
		$self->get_logger()->log(CYAN.'Fetching latest changes from '.$self->get_remote().'...'.RESET);
		$self->get_git()->fetch($self->get_remote());

		for my $branch ($self->get_from(), $self->get_environment()) {
			unless (any { $_ eq $branch } $self->get_local_branches()) {
				$self->create_and_switch_to_branch($branch);
			}
			$self->update_branch($branch);
		}

		$self->merge($self->get_from(), $self->get_environment());

		$self->update_submodules();

		$self->get_logger()->log(
			BOLD.GREEN.'Done. Please check the changes and '
				. '"git push '.$self->get_remote().' '.$self->get_environment().'"'
					.' them.'.RESET
		);
	}
	catch {
		my $error = $_;
		$error =~ s{^(?:\[.*\]\s)*}{}x; # Remove prefixes
		$self->get_logger()->log(BOLD.RED.'Failed to update. Error was: '.RESET.$error);
	};

	return;
}



sub get_local_branches {
	my ($self) = @_;

	my @branches;
	for my $branch ($self->get_git()->branch()) {
		$branch =~ s{^[*\s]*}{}x;
		push @branches, $branch;
	}

	return @branches;
}



sub remote_branch_for {
	my ($self, $branch) = @_;

	return $self->get_remote().'/'.$branch;
}



sub create_and_switch_to_branch {
	my ($self, $branch) = @_;

	$self->get_proxy_logger(BLUE.'[create-branch] '.RESET)->log(
		'Creating local branch '.$branch.' from '.$self->remote_branch_for($branch).'...'
	);
	$self->get_git()->checkout('-b', $branch, $self->remote_branch_for($branch));

	return;
}



sub update_branch {
	my ($self, $branch) = @_;

	my $logger = $self->get_proxy_logger(YELLOW.'[update-branch] '.RESET);

	my $remote_branch = $self->remote_branch_for($branch);
	$logger->log(
		'Updating local branch '.$branch.' from '.$remote_branch.'...'
	);
	$self->get_git()->checkout($branch);
	try {
		$logger->log($self->get_git()->merge('--ff-only', $remote_branch));
	}
	catch {
		chomp;
		$logger->log_fatal(
			"$_ - does ".$remote_branch.' exist and is local branch '
				.$branch.' not diverged from it?'
		);
	};

	return;
}



sub merge {
	my ($self, $from, $to) = @_;

	my $logger = $self->get_proxy_logger(MAGENTA.'[merge] '.RESET);
	$logger->log('Merging '.$from.' into '.$to.'...');
	$self->get_git()->checkout($to);
	$logger->log($self->get_git()->merge('--no-ff', $from));
	return;
}



sub update_submodules {
	my ($self) = @_;

	my $workdir = pushd($self->get_workdir());
	my $logger = $self->get_proxy_logger(YELLOW.'[update-submodules] '.RESET);
	$logger->log('Updating submodules...');
	if (my @updated = $self->get_git()->submodule('update', '--init')) {
		$logger->log($_) for @updated;
	}
	else {
		$logger->log('No submodules to update.');
	}

	return;
}

__PACKAGE__->meta()->make_immutable();

1;


__END__
=pod

=head1 NAME

App::Puppet::Environment::Updater - Update a Puppet environment in a Git branch

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

	use App::Puppet::Environment::Updater;

	App::Puppet::Environment::Updater->new_with_options()->run();

=head1 DESCRIPTION

App::Puppet::Environment::Updater is intended to update Puppet environments which
are in Git branches. There are many ways to organize a Puppet setup and Puppet
environments, and this application supports the following approach:

=over

=item *

There is one Git repository with four branches, each of which represents a
Puppet environment:

=over

=item *

C<development>

=item *

C<test>

=item *

C<staging>

=item *

C<production>

=back

=item *

Each branch contains a C<site.pp> with the Puppet nodes that are present in the
environment represented by the branch.

=item *

Puppet modules are included as Git submodules, usually below C<modules>. It's not
necessary to use Git submodules, but it simplifies reuse of the Puppet modules in
other projects.

=back

The sandbox of the Git repository usually looks about as follows:

	.
	|-- modules
	|   |-- module1
	|   |   |-- manifests
	|   |   |   `-- init.pp
	|   |   `-- templates
	|   |       `-- template1.erb
	|   `-- module2
	|       |-- files
	|       |   `-- file1.pl
	|       `-- manifests
	|           `-- init.pp
	`-- site.pp

In order to move a change from eg. C<development> to C<testing>, one can usually
simply merge the C<development> branch into the C<testing> branch and update the
submodules. This application tries to automate this and work around some of the
pitfalls that exist on the way.

=head1 METHODS

=head2 new

Constructor, creates new instance of the application.

=head3 Parameters

This method expects its parameters as a hash reference. See C<--usage> to see
which parameters can be passed on the command line.

=over

=item from

The branch to merge from.

=item environment

The branch to merge to.

=item remote

The Git remote where changes can be fetched from and should be pushed to. B<This
application does currently not push any changes.> Defaults to C<origin>.

=item workdir

Directory with the Git sandbox that should be used. Defaults to the current
directory, but should point to the toplevel of the working tree.

=item git

The L<Git::Wrapper|Git::Wrapper> instance to use.

=item logger

The L<Log::Dispatchouli|Log::Dispatchouli> instance to use.

=back

=head2 get_proxy_logger

Get a proxy logger with a given prefix.

=head3 Parameters

This method expects positional parameters.

=over

=item prefix

A prefix which should be set in the proxy logger.

=back

=head3 Result

A L<Log::Dispatchouli::Proxy|Log::Dispatchouli::Proxy> instance.

=head2 run

Run the application.

=head3 Result

Nothing on success, an exception otherwise.

=head2 get_local_branches

Get a list with local branches.

=head3 Result

The local branches.

=head2 remote_branch_for

Construct the name of a remote branch given a branch name.

=head3 Parameters

This method expects positional parameters.

=over

=item branch

Name of the branch the remote branch name should be constructed for.

=back

=head3 Result

The name of the remote branch.

=head2 create_and_switch_to_branch

Create a local branch starting at the corresponding remote branch and switch to
it.

=head3 Parameters

This method expects positional parameters.

=over

=item branch

Name of the branch.

=back

=head3 Result

Nothing on success, an exception otherwise.

=head2 update_branch

Update a local branch from the corresponding remote branch, using a fast-forward
merge.

=head3 Parameters

This method expects positional parameters.

=over

=item branch

The name of the branch which should be updated.

=back

=head3 Result

Nothing on success, an exception otherwise.

=head2 merge

Merge a given branch into another branch.

=head3 Parameters

This method expects positional parameters.

=over

=item from

The branch to merge from.

=item to

The branch to merge to.

=back

=head3 Result

Nothing on success, an exception otherwise.

=head2 update_submodules

Update the submodules.

=head3 Result

Nothing on success, an exception otherwise.

=head1 SEE ALSO

=over

=item *

L<http://www.puppetlabs.com/> - Puppet

=item *

L<http://docs.puppetlabs.com/guides/environment.html> - How to configure Puppet
environments.

=item *

L<http://git-scm.com/> - Git

=back

=head1 AUTHOR

Manfred Stock <mstock@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Manfred Stock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

