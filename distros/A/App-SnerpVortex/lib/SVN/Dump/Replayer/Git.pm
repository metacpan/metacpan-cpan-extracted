package SVN::Dump::Replayer::Git;
BEGIN {
  $SVN::Dump::Replayer::Git::VERSION = '1.000';
}

{
	# TODO - Refactor into its own class?
	# It feels odd making an entire class for a data structure.
	package SVN::Dump::Replayer::Git::Author;
BEGIN {
  $SVN::Dump::Replayer::Git::Author::VERSION = '1.000';
}
	use Moose;
	has name  => ( is => 'ro', isa => 'Str', required => 1 );
	has email => ( is => 'ro', isa => 'Str', required => 1 );
	1;
}

{
	# TODO - Refactor into its own class?
	# It feels odd making an entire class for a data structure.
	package GitTag;
BEGIN {
  $GitTag::VERSION = '1.000';
}
	use Moose;
	has revision => ( is => 'ro', isa => 'SVN::Dump::Revision', required => 1 );
}

use Moose;
extends 'SVN::Dump::Replayer';
use Carp qw(croak cluck);
use File::Path qw(mkpath);

has authors_file    => ( is => 'ro', isa => 'Maybe[Str]' );
has authors => (
	is => 'rw',
	isa => 'HashRef[SVN::Dump::Replayer::Git::Author]',
);

has files_needing_add => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { {} }
);

has directories_needing_add => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { {} }
);

has needs_commit => ( is => 'rw', isa => 'Bool', default => 0 );

has revisions_between_gc => ( is => 'ro', isa => 'Int', default => 1000 );
has revisions_until_gc => ( is => 'rw', isa => 'Int', default => 1000 );

has tags => ( is => 'rw', isa => 'HashRef[GitTag]', default => sub { {} } );

has current_branch => ( is => 'rw', isa => 'Str',  default => 'master' );
has current_rw     => ( is => 'rw', isa => 'Bool', default => 1 );

###

after on_revision_done => sub {
	my ($self, $revision_id) = @_;
	my $final_revision = $self->arborist()->pending_revision();
	$self->git_commit($final_revision);

	# Changes are done.  Remember any copy sources that pull from this
	# revision.  For git, a copy source is a revision SHA1 and
	# branch-relative path.
	#
	# TODO - If the copy source is only used to "branch" or "tag"
	# something, then we can rename the branch or tag instead of saving
	# a copy here.
	#
	# TODO - Git can copy files & directories across branches.  Do we
	# even need the tarballs?

	$self->push_dir($self->replay_base());

	COPY: foreach my $copy_source_obj (
		$self->arborist()->get_copy_sources_for_revision($revision_id)
	) {
		my $cps_kind = $copy_source_obj->kind();
		my $cps_path = $copy_source_obj->src_path();

		$self->log("CPY) saving $cps_kind $cps_path for later.");

		# Switch to the copy source branch.
		my $src_info_method = "get_" . $cps_kind . "_analysis_info";
		my $src_dir_info = $self->arborist()->$src_info_method(
			$revision_id, $cps_path
		);

		$self->set_branch(
			$final_revision,
			$src_dir_info->ent_type(),
			$src_dir_info->ent_name(),
		);

		my $relative_src_path = $src_dir_info->fix_path($cps_path);
		$relative_src_path = "." unless length $relative_src_path;

		# Get the copy depot information, based on absolute path/rev tuples.
		my ($copy_depot_id, $copy_depot_path) = $self->calculate_depot_info(
			$cps_path, $revision_id
		);

		# Tarball a directory.
		if ($cps_kind eq "dir") {
			$copy_depot_path .= ".tar.gz";
			$self->log(
				"CPY) Saving directory $relative_src_path in: $copy_depot_path"
			);
			$self->push_dir($relative_src_path);
			$self->do_or_die("tar", "czf", $copy_depot_path, ".");
			$self->pop_dir();
			next COPY;
		}

		$self->log("CPY) Saving file $relative_src_path in: $copy_depot_path");
		$self->copy_file_or_die($relative_src_path, $copy_depot_path);
		next COPY;
	}

	$self->pop_dir();
};

# Analysis is generic for Subversion.  Map entity names to Git
# specific ones.

before on_walk_begin => sub {
	my $self = shift;

	# Remove from consideration all copy sources that create entities.
	# Branch and tag creation doesn't really copy files.

	SOURCE: foreach my $source ($self->arborist()->get_all_copy_sources()) {

		# Only directories can be entities, so skip everything else.
		next SOURCE if $source->kind() ne "dir";

		COPY: foreach my $copy (
			$self->arborist()->get_all_copies_for_src($source)
		) {

			my $destination_dir_info = $self->arborist()->get_dir_analysis_info(
				$copy->dst_rev(),
				$copy->dst_path(),
			);

			next COPY unless (
				defined($destination_dir_info) and $destination_dir_info->is_entity()
			);

			$self->arborist()->ignore_copy($copy);
		}
	}
};

after on_walk_begin => sub {
	my $self = shift;

	# Set up authors mapping.
	if (defined $self->authors_file()) {
		# Initialize it.  Probably can use Moose to tell us it's been set.
		$self->authors({});

		open my $fh, "<", $self->authors_file() or confess $!;
		while (<$fh>) {
			my ($nick, $name, $email) = (/^\s*([^=]*?)\s*=\s*([^<]*?)\s*<(\S+?)>/);

			$name = $nick unless defined $name and length $name;

			$self->authors()->{$nick} = SVN::Dump::Replayer::Git::Author->new(
				name  => $name,
				email => $email,
			);
		}
	}

	$self->do_rmdir($self->replay_base()) if -e $self->replay_base();
	$self->do_mkdir($self->replay_base());

	$self->push_dir($self->replay_base());
	$self->do_or_die("git", "init", ($self->verbose() ? () : ("-q")));

	# Perform an initial commit so that the master branch is ready.
	# Needed in case the repository branches right away.
	# TODO - Detect when needed, and only use then.
	my $initial_file = "created_by_snerp_vortex.txt";
	open my $fh, ">", $initial_file or die $!;
	print $fh "This repository was created by Snerp Vortex.\n";
	close $fh;
	$self->do_or_die("git", "add", "-f", $initial_file);
	$self->needs_commit(1);

	$self->pop_dir();
};

sub on_branch_directory_creation {
	my ($self, $change, $revision) = @_;

	$self->push_dir($self->replay_base());

	# Current master branch.
	$self->set_branch($revision, $change->entity_type(), $change->entity_name());

	my $new_branch_name = $change->entity_name();

	# New branch is "master"?  But we already have that.
	# Switch over, rather than re-create (and fail).
	# TODO - I don't like this special case.  How to get rid of it?
	if ($new_branch_name eq "master") {
		$self->do_or_die("git", "checkout", "-q", $new_branch_name);
	}
	else {
		$self->do_or_die("git", "checkout", "-q", "-b", $new_branch_name);
	}

	$self->current_branch($new_branch_name);

	$self->pop_dir();
}

sub on_branch_directory_copy {
	my ($self, $change, $revision) = @_;

	# Branches must be created from containers.

	# TODO - Subversion supports "silly" things like branching and
	# tagging subdirectories within entities.
	# TODO - At the moment, the best we can do is tag or branch the
	# entire containing entity.
	# TODO - Consider identifying subdirectories that are treated like
	# sub-branches and mapping them to proper branches.  Then they can
	# be tagged as proper entities.

	$self->log(
		"GIT) creating branch from ", $change->src_path(),
		" to ", $change->path()
	);

	$self->push_dir($self->replay_base());
	$self->set_branch(
		$revision,
		$change->src_entity_type(),
		$change->src_entity_name()
	);

	my $new_branch_name = $change->entity_name();
	$self->do_or_die("git", "checkout", "-q", "-b", $new_branch_name);
	$self->current_branch($new_branch_name);
	$self->pop_dir();
	return;
}

sub on_directory_copy {
	my ($self, $change, $revision) = @_;
	$self->push_dir($self->replay_base());
	$self->set_branch(
		$revision,
		$change->entity_type(),
		$change->entity_name()
	);

	#my $dst_path = $self->arborist()->calculate_relative_path($change->path());
	my $dst_path = $change->rel_path();
	$self->do_directory_copy($change, $revision, $dst_path);
	$self->directories_needing_add()->{$dst_path} = 1;
	$self->pop_dir();
}

sub on_directory_creation {
	my ($self, $change, $revision) = @_;
	$self->push_dir($self->replay_base());
	$self->set_branch($revision, $change->entity_type(), $change->entity_name());
	$self->do_mkdir($change->rel_path());
	$self->pop_dir();
}

sub on_directory_deletion {
	my ($self, $change, $revision) = @_;

	# TODO - Doesn't need a commit if $rel_path is a directory that
	# contains no files.
	#   1. find $rel_path -type f
	#   2. If anything comes up, then we need a commit.
	#   3. Otherwise, we don't need one on account of this.

	# First try git rm, to remove from the repository.
	$self->push_dir($self->replay_base());
	$self->set_branch($revision, $change->entity_type(), $change->entity_name());

	my $rm_path = $change->rel_path();
	confess "can't remove nonexistent directory $rm_path" unless -e $rm_path;

	$self->git_env_setup($revision);

	$self->do_sans_die(
		"git", "rm", "-r", "--ignore-unmatch", "-f", "-q", "--",
		$rm_path,
	);

	# Second, try a plain filesystem remove in case the file hasn't yet
	# been staged.  Since git-rm may have removed any number of parent
	# directories for $rel_path, we only try to rmtree() if it still
	# exists.

	$self->do_rmdir($rm_path) if -e $rm_path;

	# Git cleans up directories; svn assumes they exist.
	$self->ensure_parent_dir_exists($rm_path);

	delete $self->directories_needing_add()->{$rm_path};
	$self->needs_commit(1);

	$self->pop_dir();
}

sub on_branch_directory_deletion {
	my ($self, $change, $revision) = @_;

	$self->push_dir($self->replay_base());

	my $branch_to_delete = $change->entity_name();

	# Get off the branch if we're deleting the one we're on.
	if ($branch_to_delete eq $self->current_branch()) {
		my $escape_dir_info = $self->arborist()->get_dir_analysis_info(
			$revision->id(),
			""
		);

		$self->set_branch(
			$revision,
			$escape_dir_info->ent_type(),
			$escape_dir_info->ent_name(),
		);
	}

	$self->git_env_setup($revision);
	$self->do_or_die("git", "branch", "-D", $change->entity_name());
	$self->pop_dir();
}

sub on_file_change {
	my ($self, $change, $revision) = @_;
	$self->push_dir($self->replay_base());
	$self->set_branch($revision, $change->entity_type(), $change->entity_name());
	my $rewrite_path = $change->rel_path();

	if ($self->rewrite_file($change, $rewrite_path)) {
		$self->files_needing_add()->{$rewrite_path} = 1;
	}
	$self->pop_dir();
}

sub on_file_copy {
	my ($self, $change, $revision) = @_;
	$self->push_dir($self->replay_base());
	$self->set_branch($revision, $change->entity_type(), $change->entity_name());

	my $dst_path = $change->rel_path();

	$self->do_file_copy($change, $revision);
	$self->files_needing_add()->{$dst_path} = 1;
	$self->pop_dir();
}

sub on_file_creation {
	my ($self, $change, $revision) = @_;
	$self->push_dir($self->replay_base());
	$self->set_branch($revision, $change->entity_type(), $change->entity_name());
	my $create_path = $change->rel_path();

	$self->write_new_file($change, $create_path);
	$self->files_needing_add()->{$create_path} = 1;
	$self->pop_dir();
}

sub on_file_deletion {
	my ($self, $change, $revision) = @_;

	$self->push_dir($self->replay_base());
	$self->set_branch($revision, $change->entity_type(), $change->entity_name());

	my $rm_path = $change->rel_path();
	confess "can't remove nonexistent file $rm_path" unless -e $rm_path;

	$self->git_env_setup($revision);

	$self->do_sans_die(
		"git", "rm", "-r", "--ignore-unmatch", "-f", "-q", "--",
		$rm_path,
	);

	# git-rm doesn't always remove the files right away.
	$self->do_rmdir($rm_path) if -e $rm_path;

	$self->ensure_parent_dir_exists($rm_path);
	$self->pop_dir();

	delete $self->files_needing_add()->{$rm_path};
	$self->needs_commit(1);
}

sub on_tag_directory_copy {
	my ($self, $change, $revision) = @_;

	$self->git_commit($revision);

	my $tag_name = $change->entity_name();

	$self->push_dir($self->replay_base());
	$self->set_branch(
		$revision,
		$change->src_entity_type(),
		$change->src_entity_name()
	);

	$self->git_env_setup($revision);

	$self->pipe_into_or_die($revision->message(), "git tag -a -F - $tag_name");

	$self->pop_dir();

	$self->log("TAG) setting tag $tag_name = $revision");
	$self->tags()->{$tag_name} = $revision;
}

sub on_tag_directory_creation {
	my ($self, $change, $revision) = @_;

	$self->git_commit($revision);

	my $tag_name = $change->entity_name();
	$self->push_dir($self->replay_base());
	$self->set_branch($revision, $change->entity_type(), $change->entity_name());

	$self->git_env_setup($revision);

	$self->pipe_into_or_die($revision->message(), "git tag -a -F - $tag_name");
	$self->pop_dir();

	$self->log("TAG) setting tag $tag_name = $revision");
	$self->tags()->{$tag_name} = $revision;
}

sub on_tag_directory_deletion {
	my ($self, $change, $revision) = @_;

	# Tag deletion is out of band.
	$self->push_dir($self->replay_base());
	$self->git_env_setup($revision);
	$self->do_or_die("git", "tag", "-d", $change->entity_name());
	$self->pop_dir();

	$self->log("TAG) deleting tag ", $change->entity_name());
	delete $self->tags()->{$change->entity_name()};
}

sub on_file_rename {
	my ($self, $change, $revision) = @_;
	$self->push_dir($self->replay_base());
	$self->set_branch($revision, $change->entity_type(), $change->entity_name());

	confess "target of file rename (", $change->rel_path(), ") exists" if (
		-e $change->rel_path()
	);

	$self->git_env_setup($revision);

	$self->do_sans_die(
		"git", "mv", $change->src_rel_path(), $change->rel_path()
	) or rename(
		$change->rel_src_path(), $change->rel_path()
	) or confess(
		"file rename from ", $change->rel_src_path(),
		" to ", $change->rel_path(),
		" failed: $!"
	);

	$self->ensure_parent_dir_exists($change->src_rel_path());
	$self->pop_dir();
	$self->needs_commit(1);
}

sub on_rename {
	my ($self, $change, $revision) = @_;
	$self->push_dir($self->replay_base());
	$self->set_branch($revision, $change->entity_type(), $change->entity_name());

	confess "target of rename (", $change->rel_path(), ") already exists" if (
		-e $change->rel_path()
	);

	$self->git_env_setup($revision);

	$self->do_sans_die(
		"git", "mv", $change->src_rel_path(), $change->rel_path()
	) or rename(
		$change->src_rel_path(), $change->rel_path()
	) or confess(
		"rename from ", $change->src_rel_path(),
		" to ", $change->rel_path(),
		" failed: $!"
	);

	$self->ensure_parent_dir_exists($change->src_rel_path());
	$self->pop_dir();
	$self->needs_commit(1);
}

sub on_directory_rename {
	my ($self, $change, $revision) = @_;
	$self->push_dir($self->replay_base());
	$self->set_branch($revision, $change->entity_type(), $change->entity_name());

	confess "target of dir rename (", $change->rel_path(), ") already exists" if (
		-e $change->rel_path()
	);

	$self->do_sans_die(
		"git", "mv", $change->src_rel_path(), $change->rel_path()
	) or rename(
		$change->src_rel_path(), $change->rel_path()
	) or confess(
		"directory rename from ", $change->src_rel_path(),
		" to ", $change->rel_path(),
		" failed: $!"
	);

	$self->ensure_parent_dir_exists($change->src_rel_path());
	$self->pop_dir();
	$self->needs_commit(1);
}

sub on_branch_rename {
	my ($self, $change, $revision) = @_;

	$self->push_dir($self->replay_base());
	$self->git_env_setup($revision);
	$self->do_or_die(
		"git", "branch", "-m",
		$change->src_entity_name(),
		$change->entity_name(),
	);
	$self->pop_dir();

	# Did we just rename the current branch?
	$self->current_branch($change->entity_name()) if (
		$change->src_entity_name() eq $self->current_branch()
	);
}

sub on_tag_rename {
	my ($self, $change, $revision) = @_;

	$self->push_dir($self->replay_base());

	my $old_tag_name = $change->src_entity_name();
	my $new_tag_name = $change->entity_name();

	# Find the change referenced by the old tag.
	my $old_tag_ref = $self->pipe_out_of_or_die(
		"git rev-parse -- $old_tag_name | tail -1"
	);
	confess "unreferenced tag $old_tag_name" unless (
		defined $old_tag_ref and length $old_tag_ref
	);
	chomp $old_tag_ref;

	# Get the old revision, so we can reuse its message.
	my $old_revision = delete $self->tags()->{$old_tag_name};
	$self->log("TAG) renaming from tag $old_tag_name = $old_revision");

	# Create the new tag with the old reference.
	$self->git_env_setup($old_revision);
	$self->pipe_into_or_die(
		$old_revision->message(),
		"git tag -a -F - $new_tag_name $old_tag_ref"
	);

	# Delete the old tag.
	$self->git_env_setup($revision);
	$self->do_or_die("git", "tag", "-d", $old_tag_name);

	$self->pop_dir();

	$self->tags()->{$new_tag_name} = $old_revision;
	$self->log("TAG) renaming to tag $new_tag_name = $old_revision");
}

### Git helpers.

sub git_commit {
	my ($self, $revision) = @_;

	unless ($self->current_rw()) {
		confess(
			"attempting a commit on read-only entity ",
			$self->current_branch()
		);
	}

	$self->push_dir($self->replay_base());

	# Every directory added is exploded into its constituent files.
	# Try to avoid "git-add --all".  It traverses the entire project
	# tree, which quickly gets expensive.

	if (scalar keys %{$self->directories_needing_add()}) {
		foreach my $dir (keys %{$self->directories_needing_add()}) {
			# TODO - Use File::Find when shell characters become an issue.
			foreach my $file (`find $dir -type f`) {
				chomp $file;
				$self->files_needing_add()->{$file} = 1;
			}
		}

		$self->directories_needing_add({});
		$self->needs_commit(1);
	}

	$self->git_env_setup($revision);

	my $needs_status = 1;
	if (scalar keys %{$self->files_needing_add()}) {
		# TODO - Break it up if the files list is too big.
		$self->do_or_die("git", "add", "-f", keys(%{$self->files_needing_add()}));
		$self->files_needing_add({});
		$self->needs_commit(1);
		$needs_status = 0;
	}

	unless ($self->needs_commit()) {
		$self->log("skipping git commit");
		$self->pop_dir();
		return;
	}

	my $git_commit_message_file = "/tmp/git-commit-$$.txt";

	my $message = $revision->message();
	$message = "(no message)" unless defined $message and length $message;

	open my $tmp, ">", $git_commit_message_file or confess $!;
	print $tmp $message or confess $!;
	close $tmp or confess $!;

	$self->git_env_setup($revision);

	# Some changes seem to alter no files.  We can detect whether a
	# commit is needed using git-status.  Otherwise, if we guess wrong,
	# git-commit will fail if there's nothing to commit.  We bother
	# checking git-commit because we do want to catch errors.

	# TODO - git-status is slow after a while.  Can we do something
	# smart to avoid it in all cases?
	if (
		!$needs_status or
		$self->do_sans_die("git status >/dev/null 2>/dev/null")
	) {
		$self->do_or_die(
			"git", "commit",
			($self->verbose() ? () : ("-q")),
			"--allow-empty", "-F", $git_commit_message_file
		);
	}

	unlink $git_commit_message_file;

	# Map between Subversion revisions and Git commits.
	chomp(my $git_id = qx(git rev-list -n 1 HEAD));
	$self->arborist()->map_revisions($revision->id(), $git_id);

	$self->needs_commit(0);
	$self->pop_dir();

	# Check for the need to GC.
	$self->revisions_until_gc( $self->revisions_until_gc() - 1 );
	if ($self->revisions_until_gc() < 1) {
		$self->do_git_gc();
		$self->revisions_until_gc( $self->revisions_between_gc() );
	}

	return;
}

sub do_git_gc {
	my $self = shift;
	$self->push_dir($self->replay_base());
	$self->do_or_die("git", "gc", ($self->verbose() ? () : ("--quiet")));
	$self->pop_dir();
}

### Helper methods.

#sub qualify_change_path {
#	my ($self, $change) = @_;
#	return $self->calculate_path($change->path());
#}

sub calculate_path {
	my ($self, $path) = @_;

	my $full_path = $self->replay_base() . "/" . $path;
	$full_path =~ s!//+!/!g;

	return $full_path;
}

sub git_env_setup {
	my ($self, $revision) = @_;

	confess "bad revision $revision" unless defined $revision and ref($revision);

	$ENV{GIT_COMMITTER_DATE} = $ENV{GIT_AUTHOR_DATE} = $revision->time();

	my $rev_author = $revision->author();

	my ($author_name, $author_email);
	if ($self->authors()) {
		my $git_author = $self->authors()->{$rev_author};
		unless (defined $git_author and length $git_author) {
			confess(
				"svn author '$rev_author' doesn't seem to be in your authors file"
			);
		}
		$author_name  = $git_author->name();
		$author_email = $git_author->email();
	}
	else {
		$author_name  = $rev_author;
		$author_email = "$rev_author\@example.com";
	}

	# TODO - Use the svn repository's GUID as the email host.
	$ENV{GIT_COMMITTER_NAME}  = $ENV{GIT_AUTHOR_NAME}  = $author_name;
	$ENV{GIT_COMMITTER_EMAIL} = $ENV{GIT_AUTHOR_EMAIL} = $author_email;
}

sub ensure_parent_dir_exists {
	my ($self, $path) = @_;
	$path =~ s!/*[^/]+/*$!!;
	return unless length $path and $path ne "/";
	return if -e $path;
	$self->log("mkpath $path");
	mkpath($path) or confess "mkpath failed: $!";
}

# Assumes that the cwd is already the replay repository.
sub set_branch {
	my ($self, $revision, $ent_type, $ent_name) = @_;

	if ($ent_name eq $self->current_branch()) {
		$self->log("GIT) already on branch $ent_name");
		return;
	}

	$self->git_commit($revision);

	if ($ent_type eq "branch") {
		$self->current_rw(1);
	}
	elsif ($ent_type eq "tag") {
		$self->current_rw(0);
	}
	else {
		confess "set_branch() inappropriately called for a $ent_type $ent_name";
	}

	$self->do_sans_die("git", "checkout", "-q", $ent_name);
	$self->current_branch($ent_name);

	# TODO - We also need to prune the paths within the entity.
	# Branches don't belong in /branch, for example.

	return;
}

# Already in the destination branch.
sub do_directory_copy {
	my ($self, $change, $revision, $branch_rel_path) = @_;

	confess "cp to $branch_rel_path failed: path exists" if -e $branch_rel_path;

	my ($copy_depot_descriptor, $copy_depot_path) = $self->get_copy_depot_info(
		$change
	);

	# Directory copy sources are tarballs.
	$copy_depot_path .= ".tar.gz";

	unless (-e $copy_depot_path) {
		confess "cp src $copy_depot_path ($copy_depot_descriptor) doesn't exist";
	}

	$self->do_mkdir($branch_rel_path);
	$self->push_dir($branch_rel_path);
	$self->do_or_die("tar", "xzf", $copy_depot_path);
	$self->pop_dir();

	$self->decrement_copy_source($change, $revision, $copy_depot_path);
}

sub do_file_copy {
	my ($self, $change, $revision) = @_;

	my $branch_rel_path = $change->rel_path();

	confess "cp to $branch_rel_path failed: path exists" if -e $branch_rel_path;

	my ($copy_depot_descriptor, $copy_depot_path) = $self->get_copy_depot_info(
		$change
	);

	unless (-e $copy_depot_path) {
		confess "cp src $copy_depot_path ($copy_depot_descriptor) doesn't exist";
	}

	# Weirdly, the copy source may not be authoritative.
	if (defined $change->content()) {
		$self->write_change_data($change, $branch_rel_path);
		$self->decrement_copy_source($change, $revision, $copy_depot_path);
		return;
	}

	# If content isn't provided, however, copy the file from the depot.
	$self->copy_file_or_die($copy_depot_path, $branch_rel_path);
	$self->decrement_copy_source($change, $revision, $copy_depot_path);
}

1;
