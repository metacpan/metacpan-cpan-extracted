package App::GitWorkspaceScanner;

use strict;
use warnings;

# External dependencies.
use Carp qw( croak );
use Data::Dumper;
use File::Spec;
use Getopt::Long;
use Git::Repository;
use Log::Any qw( $log );
use Pod::Find qw();
use Pod::Usage qw();
use Readonly;
use Try::Tiny;


=head1 NAME

App::GitWorkspaceScanner - Scan git repositories in your workspace for local changes not synced up.


=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';


=head1 DESCRIPTION

This module scans a workspace to find git repositories that are not in sync
with their remotes or that are not on an expected branch. This gives you a
snapshot of all outstanding changes in your entire workspace.


=head1 SYNOPSIS

	sudo nice ./scan_git_repositories


=head1 OPTIONS

C<Git::WorkspaceScanner> provides a C<scan_git_repositories> utility as a command
line interface to the module. It supports the following command line options:

=over 4

=item * C<--verbose>

Print out information about the analysis performed. Off by default.

	# Print out information.
	./scan_git_repositories --verbose

=item * C<--workspace>

Root of the workspace to search git repositories into. By default, the search
is performed on '/', but you can use any absolute path.

	./scan_git_repositories --workspace=$HOME


=item * C<--allow_untracked_files>

Set whether untracked files should generate a warning in the report. Currently
on by default, but this is likely to change in the near future as we add/clean
up our .gitignore files.

	# Do not warn on untracked files (default).
	./scan_git_repositories --allow_untracked_files=0

	# Warn on untracked files.
	./scan_git_repositories --allow_untracked_files=1

=item * C<--allowed_branches>

Generate a warning if the current branch doesn't match one of the branches
specified. Set to C<master> default.

	# Allow only using the master branch.
	./scan_git_repositories

	# Allow only using the master branch.
	./scan_git_repositories --allowed_branches=master

	# Allow only using the master and production branches.
	./scan_git_repositories --allowed_branches=master,production

=item * C<--allow_any_branches>

Disable the check performed by C<--allowed_branches>, which is set to force
using the C<master> branch by default.

	# Don't check the branch the repository is on.
	./scan_git_repositories --allow_any_branches=1

=item * C<--whitelist_repositories>

Excludes specific repositories from the checks performed by this script. The
argument accepts a comma-separated list of paths to ignore, but by default no
repositories are whitelisted.

	# Whitelist /root/my_custom_repo
	./scan_git_repositories --whitelist_repositories=/root/my_custom_repo

=back


=head1 CAVEATS

=over 4

=item *

This script currently uses C<locate> to scan the current machine for git
repositories, so this only works for Linux/Unix machines.

=item *

If you are not using C<--workspace> to limit the scan to files on which you
have read permissions, this script needs to be run as root.

=item *

You should have C<updatedb> in your crontab running daily, to ensure that new
repositories are picked up.

=item *

You should run this script using C<nice>. While it uses C<locate>, it still has
an impact on the file cache and using C<nice> will help mitigate any potential
issues.

=back

=cut

Readonly::Scalar my $FILE_STATUS_PARSER =>
{
	'??' => 'untracked',
	'A'  => 'added',
	'D'  => 'deleted',
	'M'  => 'modified',
	'R'  => 'moved',
};


=head1 FUNCTIONS

=head2 new()

Create a new C<Git::WorkspaceScanner> object.

	my $scanner = Git::WorkspaceScanner->new(
		arguments => \@arguments,
	);

Arguments:

=over 4

=item * arguments I<(mandatory)>

An arrayref of arguments passed originally to the command line utility.

=back

=cut

sub new
{
	my ( $class, %args ) = @_;

	# Verify arguments.
	my $arguments = delete( $args{'arguments'} );
	croak 'The following argument(s) are not valid: ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Create the object.
	my $self = bless( {}, $class );

	# Parse the arguments provided.
	$self->parse_arguments( $arguments );

	# If --help was passed, print out usage info and exit.
	if ( $self->{'help'} )
	{
		Pod::Usage::pod2usage(
			'-verbose'  => 99,
			'-sections' => 'NAME|SYNOPSIS|OPTIONS',
			'-input'    => Pod::Find::pod_where(
				{-inc => 1},
				__PACKAGE__,
			),
		);
	}

	return $self;
}


=head2 parse_arguments()

Parse the options passed via the command line arguments and make sure there is
no conflict or invalid settings.

	my $options = $scanner->parse_arguments();

=cut

sub parse_arguments
{
	my ( $self, $arguments ) = @_;

	# Parse arguments.
	Getopt::Long::GetOptionsFromArray(
		$arguments,
		$self,
		'verbose',
		'allowed_branches=s',
		'allow_any_branches=i',
		'allow_untracked_files=i',
		'whitelist_repositories=s',
		'workspace=s',
		'help',
	) || croak "Error parsing command line arguments";

	# --help is off by default.
	$self->{'help'} //= 0;

	# --verbose is off by default.
	$self->{'verbose'} = $self->{'verbose'} // 0;
	croak "Invalid value for --verbose\n"
		if $self->{'verbose'} !~ /\A[01]\z/;

	# Set '/' as the default for --workspace.
	$self->{'workspace'} //= '/';

	# Force a trailing slash.
	$self->{'workspace'} =~ s|/+$|/|;

	# --allowed_branches cannot be combined with --allow_any_branches.
	croak "--allowed_branches cannot be combined with --allow_any_branches\n"
		if defined( $self->{'allowed_branches'} ) && defined( $self->{'allow_any_branches'} );

	# --allow_any_branches is off by default.
	$self->{'allow_any_branches'} //= 0;
	croak "--allow_any_branches must be set to either 0 or 1"
		if $self->{'allow_any_branches'} !~ /\A[01]\z/;

	# --allow_untracked_files is off by default.
	$self->{'allow_untracked_files'} //= 0;
	croak "--allow_untracked_files must be set to either 0 or 1"
		if $self->{'allow_untracked_files'} !~ /\A[01]\z/;

	# Specific logic when we restrict which branches are valid.
	if ( !$self->{'allow_any_branches'} )
	{
		# It doesn't matter whether it was an explicit choice or not to
		# restrict valid branches, set the option to 0 for future tests.
		$self->{'allow_any_branches'} = 0;

		# Default --allowed_branches to master.
		$self->{'allowed_branches'} //= 'master';
	}

	# Check that the paths provided to --whitelist_repositories are valid.
	$self->{'whitelist_repositories'} //= '';
	my @whitelist_repositories = ();
	foreach my $path ( split( /,/, $self->{'whitelist_repositories'} ) )
	{
		if ( -d $path )
		{
			# Ensure a trailing slash.
			$path =~ s/\/$//;
			push( @whitelist_repositories, "$path/" );
		}
		else
		{
			print "Warning: the path >$path< provided via --whitelist_repositories is not valid and will be skipped.\n";
		}
	}
	$self->{'whitelist_repositories'} = \@whitelist_repositories;

	$self->{'verbose'} && $log->info( 'Finished parsing arguments.' );

	return;
}


=head2 get_git_repositories()

Return a list of all the git repositories on the machine.

	my $git_repositories = get_git_repositories();

=cut

sub get_git_repositories
{
	my ( $self ) = @_;

	if ( !defined( $self->{'git_repositories'} ) )
	{
		if ( $self->{'verbose'} )
		{
			$log->infof( "Running as user '%s'.", getpwuid( $< ) );
			$log->infof( "Scanning workspace '%s'.", $self->{'workspace'} );
		}

		# Find .git directories.
		# TODO: convert to not use backticks.
		# TODO: find a way to generalize to non-Unix systems.
		# TODO: generalize to handle .git repositories that are outside of their
		#       repos (rare).
		$self->{'verbose'} && $log->info( "Locate .git directories." );
		my @locate_results = `locate --basename '\\.git'`; ## no critic (InputOutput::ProhibitBacktickOperators)
		$self->{'verbose'} && $log->infof( "Found %s potential directories.", scalar( @locate_results ) );

		$self->{'git_repositories'} = [];
		foreach my $scanned_path ( @locate_results )
		{
			chomp( $scanned_path );
			$self->{'verbose'} && $log->infof( "Evaluating path %s.", $scanned_path );

			# Parse the path.
			my ( $volume, $git_repository, $file ) = File::Spec->splitpath( $scanned_path );
			if ( $file ne '.git' )
			{
				$self->{'verbose'} && $log->infof( " -> '%s' is not a .git directory after all.", $file );
				next;
			}
			if ( ! -d $git_repository )
			{
				$self->{'verbose'} && $log->infof( " -> '%s' is not a directory.", $git_repository );
				next;
			}

			# Skip paths outside of the workspace.
			if ( $git_repository !~ /^\Q$self->{'workspace'}\E/x )
			{
				$self->{'verbose'} && $log->infof( " -> '%s' is not inside the scanned space.", $git_repository );
				next;
			}

			# Skip whitelisted repositories.
			if ( scalar( grep { $_ eq $git_repository } @{ $self->{'whitelist_repositories'} } ) != 0 )
			{
				$self->{'verbose'} && $log->infof( " -> '%s' is whitelisted.", $git_repository );
				next;
			}

			push( @{ $self->{'git_repositories'} }, $git_repository );
			$self->{'verbose'} && $log->info( " -> Added to the list of repositories!" );
		}
	}

	$self->{'verbose'} && $log->infof(
		'%s relevant git directories.',
		scalar( @{ $self->{'git_repositories'} } ),
	);

	return $self->{'git_repositories'};
}


=head2 get_unclean_repositories()

Return a list of repositories with local modifications not reflected on the
origin repository.

	my $unclean_repositories = $app->get_unclean_repositories( $git_repositories );

The return value is a hashref, with the key being the path to the git
repository and the value the git status for that git repository.

=cut

sub get_unclean_repositories ## no critic (Subroutines::ProhibitExcessComplexity)
{
	my ( $self ) = @_;

	# Get the list of repositories on the machine.
	my $git_repositories = $self->get_git_repositories();

	my $report = {};
	foreach my $git_repository ( @$git_repositories )
	{
		$self->{'verbose'} && $log->infof( 'Analyzing %s.', $git_repository );

		# Detect whether we're in a submodule. Submodules behave differently for
		# branch detection in particular.
		my $is_submodule = -d File::Spec->catfile( $git_repository, '.git' ) ? 0 : 1;

		# Retrieve the status for that repository.
		# --untracked-files=all will show all the individual untracked files in
		# untracked directories, for the purpose of counting accurately untracked
		# files.
		# --branch adds branch tracking information with the prefix ##.
		my $git = Git::Repository->new( work_tree => $git_repository );
		my $git_status = $git->run( 'status', '--porcelain', '--untracked-files=all', '--branch' );

		# Parse the output of the git status command.
		my $files_stats = { map { $_ => 0 } ( values %$FILE_STATUS_PARSER, 'unknown' ) };
		my $local_branch;
		my $commits_ahead;
		foreach my $line ( split( /\n/, $git_status ) )
		{
			try
			{
				# Detect and parse branch information.
				my ( $branch_info ) = $line =~ /^##\s(.*?)$/;
				if ( defined( $branch_info ) )
				{
					my ( $remote_branch, $status );
					( $local_branch, $remote_branch, $status ) = $branch_info =~ /
						\A
						([^\. ]+)	  # Local branch name.
						(?:
							\.\.\.	 # Three dots indicate a remote branch name following next.
							([^\. ]+) # Remote branch name.
							(?:
								\s+  # Space before more information optionally follows about the respective
									 # advancement of local and remote branches.
								\[([^\]]+)\]
							)?
						)?
						\z
					/x;
					$self->{'verbose'} && $log->infof(
						"    (B) %s...%s: %s",
						$local_branch,
						( $remote_branch // '(no remote)' ),
						( $status // '(no status)' ),
					);

					# If the branch is in sync with its remote, skip.
					return
						if !defined( $status );

					# It's only an issue if the local branch is ahead of its remote,
					# since it means we have local changes.
					( $commits_ahead ) = $status =~ /^ahead\s+([0-9]+)$/
						if !defined( $commits_ahead ) || ( $commits_ahead == 0 );
					return;
				}

				# Review the status of each file.
				my ( $status, $file ) = $line =~ /^\s*(\S{1,2})\s+(.*?)$/x;
				die "The format of line >$line< is not recognized.\n"
					if !defined( $file );
				$self->{'verbose'} && $log->infof( '    (F) %s: %s.', $file, $status );

				foreach my $code ( keys %$FILE_STATUS_PARSER )
				{
					next if $status !~ /\Q$code\E/;
					my $key = $FILE_STATUS_PARSER->{ $code };
					$files_stats->{ $key }++;
					$status =~ s/\Q$code\E//g;
				}

				if ( $status ne '' )
				{
					$files_stats->{'unknown'}++;
					die "Unknown status code >$status< for file >$file<.\n";
				}
			}
			catch
			{
				chomp( $_ );
				push( @{ $report->{'errors'} }, "$git_repository: $_" );
			};
		}

		# If the --allow_untracked_files option is active, delete that status
		# from the stats so that it doesn't get reported upon.
		delete( $files_stats->{'untracked'} )
			if $self->{'allow_untracked_files'};

		# Tally the number of uncommitted file changes.
		my $total_file_issues = 0;
		foreach my $count ( values %$files_stats )
		{
			$total_file_issues += $count;
		}

		$log->infof( '    => %s.', join( ', ', map { "$_: $files_stats->{$_}" } keys %$files_stats ) )
			if $self->{'verbose'} && ( $total_file_issues > 0 );

		# Add to the report if we have uncommitted files or unpushed commits.
		if ( ( $total_file_issues > 0 ) || ( ( $commits_ahead // 0 ) > 0 ) )
		{
			$report->{ $git_repository } //= {};
			$report->{ $git_repository }->{'files_stats'} = $files_stats;
			$report->{ $git_repository }->{'files_total'} = $total_file_issues;
			$report->{ $git_repository }->{'commits_ahead'} = $commits_ahead // 0;
		}

		# Check if the branch name is authorized.
		if ( !$self->{'allow_any_branches'} && !$is_submodule )
		{
			if ( defined( $local_branch ) )
			{
				if ( scalar( grep { $local_branch eq $_ } split( /\s*,\s*/, $self->{'allowed_branches'} ) ) == 0 )
				{
					$report->{ $git_repository } //= {};
					$report->{ $git_repository }->{'is_branch_allowed'} = 0;
					$report->{ $git_repository }->{'local_branch'} = $local_branch;
				}
			}
			else
			{
				$log->warnf( "Failed to detect the local branch name for >%s<.", $git_repository );
			}
		}
	}

	return $report;
}


=head1 SEE ALSO

=over 4

=item * L<App::IsGitSynced>

=back


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitWorkspaceScanner/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitWorkspaceScanner


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitWorkspaceScanner/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-gitworkspacescanner>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-gitworkspacescanner>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitWorkspaceScanner>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2014-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
