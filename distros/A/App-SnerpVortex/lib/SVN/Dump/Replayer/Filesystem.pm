package SVN::Dump::Replayer::Filesystem;
BEGIN {
  $SVN::Dump::Replayer::Filesystem::VERSION = '1.000';
}

use Moose;
extends 'SVN::Dump::Replayer';

### Map high-level operations to a filesystem.

sub on_branch_directory_creation {
	my ($self, $change, $revision) = @_;
	$self->do_mkdir($self->qualify_change_path($change));
}

sub on_tag_directory_creation {
	my ($self, $change, $revision) = @_;
	$self->do_mkdir($self->qualify_change_path($change));
}

sub on_branch_directory_copy {
	my ($self, $change, $revision) = @_;
	$self->do_directory_copy(
		$change,
		$revision,
		$self->qualify_change_path($change)
	);
}

sub on_tag_directory_copy {
	my ($self, $change, $revision) = @_;
	$self->do_directory_copy(
		$change,
		$revision,
		$self->qualify_change_path($change)
	);
}

sub on_file_creation {
	my ($self, $change, $revision) = @_;
	$self->write_new_file($change, $self->qualify_change_path($change));
}

sub on_file_change {
	my ($self, $change, $revision) = @_;
	$self->rewrite_file($change, $self->qualify_change_path($change));
}

sub on_file_deletion {
	my ($self, $change, $revision) = @_;
	$self->do_file_deletion($self->qualify_change_path($change));
}

sub on_file_copy {
	my ($self, $change, $revision) = @_;

	my $full_dst_path = $self->qualify_change_path($change);

	die "cp to $full_dst_path failed: path exists" if -e $full_dst_path;

	my ($copy_depot_descriptor, $copy_depot_path) = $self->get_copy_depot_info(
		$change
	);

	unless (-e $copy_depot_path) {
		die "cp source $copy_depot_path ($copy_depot_descriptor) doesn't exist";
	}

	# Weirdly, the copy source may not be authoritative.
	if (defined $change->content()) {
		$self->write_change_data($change, $full_dst_path);
		$self->decrement_copy_source($change, $revision, $copy_depot_path);
		return;
	}

	# If content isn't provided, however, copy the file from the depot.
	$self->copy_file_or_die($copy_depot_path, $full_dst_path);
	$self->decrement_copy_source($change, $revision, $copy_depot_path);
}

sub on_directory_creation {
	my ($self, $change, $revision) = @_;
	$self->do_mkdir($self->qualify_change_path($change));
}

sub on_directory_deletion {
	my ($self, $change, $revision) = @_;
	$self->do_rmdir_safely($self->qualify_change_path($change));
}

sub on_branch_directory_deletion {
	my ($self, $change, $revision) = @_;
	$self->do_rmdir_safely($self->qualify_change_path($change));
}

sub on_tag_directory_deletion {
	my ($self, $change, $revision) = @_;
	$self->do_rmdir_safely($self->qualify_change_path($change));
}

sub on_directory_copy {
	my ($self, $change, $revision) = @_;
	$self->do_directory_copy(
		$change,
		$revision,
		$self->qualify_change_path($change)
	);
}

sub on_rename {
	my ($self, $change, $revision) = @_;
	$self->do_rename($change);
}

sub on_branch_rename {
	my ($self, $change, $revision) = @_;
	$self->do_rename($change);
}

sub on_tag_rename {
	my ($self, $change, $revision) = @_;
	$self->do_rename($change);
}

sub do_directory_copy {
	my ($self, $change, $revision, $full_dst_path) = @_;

	die "cp to $full_dst_path failed: path exists" if -e $full_dst_path;

	my ($copy_depot_descriptor, $copy_depot_path) = $self->get_copy_depot_info(
		$change
	);

	# Directory copy sources are tarballs.
	$copy_depot_path .= ".tar.gz";

	unless (-e $copy_depot_path) {
		die "cp source $copy_depot_path ($copy_depot_descriptor) doesn't exist";
	}

	$self->do_mkdir($full_dst_path);
	$self->push_dir($full_dst_path);
	$self->do_or_die("tar", "xzf", $copy_depot_path);
	$self->pop_dir();

	$self->decrement_copy_source($change, $revision, $copy_depot_path);
}

### Mid-level tracking.

after on_walk_begin => sub {
  my $self = shift;

	# Reset the replay directory.
	$self->do_rmdir($self->replay_base()) if -e $self->replay_base();
	$self->do_mkdir($self->replay_base());
};

after on_revision_done => sub {
	my ($self, $revision_id) = @_;

	# Changes are done.  Remember any copy sources that pull from this
	# revision.

	$self->push_dir($self->replay_base());

	COPY: foreach my $copy_source_obj (
		$self->arborist()->get_copy_sources_for_revision($revision_id)
	) {
		my $cps_kind = $copy_source_obj->kind();
		my $cps_path = $copy_source_obj->src_path();

		$self->log("CPY) saving $cps_kind $cps_path for later.");

		# Get the copy depot information, based on absolute path/rev tuples.
		my ($copy_depot_id, $copy_depot_path) = $self->calculate_depot_info(
			$cps_path, $revision_id
		);

		# Tarball a directory.
		if ($cps_kind eq "dir") {
			$copy_depot_path .= ".tar.gz";
			$self->log(
				"CPY) Saving directory $cps_path in: $copy_depot_path"
			);
			$self->push_dir($cps_path);
			$self->do_or_die("tar", "czf", $copy_depot_path, ".");
			$self->pop_dir();
			next COPY;
		}

		$self->log("CPY) Saving file $cps_path in: $copy_depot_path");
		$self->copy_file_or_die($cps_path, $copy_depot_path);
		next COPY;
	}

	$self->pop_dir();
};

### Low-level helpers.

sub qualify_change_path {
	my ($self, $change) = @_;
	return $self->calculate_path($change->path());
}

sub calculate_path {
	my ($self, $path) = @_;

	my $full_path = $self->replay_base() . "/" . $path;
	$full_path =~ s!//+!/!g;

	return $full_path;
}

1;
