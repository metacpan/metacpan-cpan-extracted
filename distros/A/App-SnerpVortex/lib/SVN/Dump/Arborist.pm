package SVN::Dump::Arborist;
BEGIN {
  $SVN::Dump::Arborist::VERSION = '1.000';
}

# TODO - Maybe rename to Replay?

# Build and manage repository trees.
# Find branches and tags based on svn copy operations.

use Moose;

use SVN::Dump::Revision;
use SVN::Analysis;
use SVN::Dump::Analyzer;

use Carp qw(croak);
use Storable qw(dclone);

has db_file_name => ( is => 'rw', isa => 'Str' );

has analysis => (
	is      => 'rw',
	isa     => 'SVN::Analysis',
	lazy    => 1,
	default => sub {
		my $self = shift;
		return SVN::Analysis->new(
			verbose       => $self->verbose(),
			db_file_name  => $self->db_file_name(),
		);
	},
);

has verbose           => ( is => 'ro', isa => 'Bool', default => 0 );
has svn_dump_filename => ( is => 'ro', isa => 'Str' );

has pending_revision => (
	is      => 'rw',
	isa     => 'SVN::Dump::Revision',
	clearer => 'clear_pending_revision',
);

##############################################################################
### Replay revisions.  Accumulate changes, then flush when revisions are done.

# Create a new SVN::Dump::Revision, and prepare it to buffer changes.

sub start_revision {
	my ($self, $revision, $author, $time, $log_message) = @_;

	croak "opening an unfinalized revision" if (
		$self->pending_revision() and $self->pending_revision()->is_open()
	);

	$self->pending_revision(
		SVN::Dump::Revision->new(
			id      => $revision,
			author  => $author,
			time    => $time,
			message => $log_message,
		)
	);

	return;
}

# A revision has finished.
# Close it, and return it for a subclass to perform.

sub finalize_revision {
	my $self = shift;

	my $new_revision = $self->pending_revision();
	$new_revision->is_open(0);
	$new_revision->optimize();

	return $new_revision;
}

# A change has added a new node to this revision.

sub add_new_node {
	my ($self, $revision, $path, $kind, $content) = @_;

	my $change;

	if ($kind eq "dir") {
		$change = SVN::Dump::Change::Mkdir->new(
			path      => $path,
			analysis  => $self->get_dir_analysis_info($revision, $path),
		);
	}
	elsif ($kind eq "file") {
		$change = SVN::Dump::Change::Mkfile->new(
			path      => $path,
			content   => $content,
			analysis  => $self->get_file_analysis_info($revision, $path),
		);
	}
	else {
		die "strange kind: $kind";
	}

	$self->pending_revision()->push_change($change);
}

# A change has copied a node to a new location.

sub copy_node {
	my ($self, $src_rev, $src_path, $revision, $dst_path, $kind, $data) = @_;

	my $get_analysis_method;

	if ($kind eq "file") {
		$get_analysis_method  = "get_file_analysis_info";
	}
	else {
		$get_analysis_method  = "get_dir_analysis_info";
	}

	my $change_class = "SVN::Dump::Change::Cp$kind";
	$self->pending_revision()->push_change(
		$change_class->new(
			analysis      => $self->$get_analysis_method($revision, $dst_path),
			path          => $dst_path,
			content       => $data,
			src_analysis  => $self->$get_analysis_method($src_rev, $src_path),
			src_path      => $src_path,
			src_rev       => $src_rev,
		)
	);
}

# An operation has touched a node.  The node's containers all the way
# back to the repository root are also touched.

sub touch_node {
	my ($self, $revision, $path, $kind, $content) = @_;

	# Some changes don't alter content.  We'll skip them, since most
	# Subversion properties aren't portable.
	if (defined $content) {
		$self->pending_revision()->push_change(
			SVN::Dump::Change::Edit->new(
				path      => $path,
				content   => $content,
				analysis  => $self->get_file_analysis_info($revision, $path),
			)
		);
	}
}

# A change has deleted a node.
# Buffer the operation in the current revision for subsequent replay.
# Also track the deletion in the replay snapshot.

sub delete_node {
	my ($self, $path, $revision) = @_;

	# Succeeds if directory.
	my $analysis = $self->get_dir_analysis_info($revision, $path);

	my ($entity, $deletion_class);
	if ($analysis) {
		$deletion_class = "SVN::Dump::Change::Rmdir";
	}
	else {
		$deletion_class = "SVN::Dump::Change::Rmfile";
		$analysis = $self->get_file_analysis_info($revision, $path);
	}

	$self->pending_revision()->push_change(
		$deletion_class->new(
			path      => $path,
			analysis  => $analysis,
		)
	);

	return;
}

# Return all copy sources for a particular revision.
sub get_copy_sources_for_revision {
	my ($self, $revision) = @_;
	return $self->analysis()->get_copy_sources_for_revision($revision);
}

sub get_all_copy_sources {
	my $self = shift;
	return $self->analysis()->get_all_copy_sources();
}

sub get_all_copies_for_src {
	my ($self, $src) = @_;
	return $self->analysis()->get_all_copies_for_src($src);
}

sub ignore_copy {
	my ($self, $copy) = @_;
	return $self->analysis()->ignore_copy($copy);
}

# Return an Analysis Dir object for the revision,path tuple.
sub get_dir_analysis_info {
	my ($self, $revision, $path) = @_;
	return $self->analysis()->get_dir_info($path, $revision);
}

# The caller has a file.  Get the analysis for its container dir.
# Basically, strip the filename off the path before getting info.
sub get_file_analysis_info {
	my ($self, $revision, $path) = @_;
	$path =~ s!/*[^/]+$!!;
	return $self->analysis()->get_dir_info($path, $revision);
}

sub map_revisions {
	my ($self, $svn_revision, $other_revision) = @_;
	return $self->analysis()->map_revisions($svn_revision, $other_revision);
}

1;
