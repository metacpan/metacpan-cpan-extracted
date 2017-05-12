package SVN::Analysis;
BEGIN {
  $SVN::Analysis::VERSION = '1.000';
}

use Moose;
use Carp qw(confess croak);

use DBI;
use SVN::Analysis::Dir;
use SVN::Analysis::Copy;

has db_file_name => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

has dbh => (
	is        => 'ro',
	isa       => 'DBI::db',
	lazy      => 1,
	default   => sub {
		my $self = shift;
		my $dbh = DBI->connect(
			'dbi:SQLite:dbname=' . $self->db_file_name(), "", ""
		);

		$dbh->do("PRAGMA case_sensitive_like = 1") or die $dbh->errstr();

		return $dbh;
	},
);

has verbose => ( is => 'ro', isa => 'Bool', default => 0 );

{
	package SVN::Analysis::TreeNode;
BEGIN {
  $SVN::Analysis::TreeNode::VERSION = '1.000';
}
	use Moose;
	extends 'SVN::Analysis::Dir';
	has name      => ( is => 'ro', isa => 'Str' );
	has children  => ( is => 'rw', isa => 'HashRef[SVN::Analysis::TreeNode]' );
	has parent    => (
		is => 'ro',
		isa => 'Maybe[SVN::Analysis::TreeNode]',
		weak_ref => 1
	);
}

### Database manipulation.

sub reset {
	my $self = shift;

	# Entities.

	$self->dbh()->do("
		CREATE TABLE dir (
			seq           INTEGER PRIMARY KEY AUTOINCREMENT,
			ent_name      TEXT,
			ent_type      TEXT,
			is_active     BOOL,
			is_add        BOOL,
			is_copy       BOOL,
			is_modified   BOOL,
			op_first      TEXT,
			op_last       TEXT,
			path          TEXT,
			path_lop      TEXT,
			path_prepend  TEXT,
			rel_path      TEXT,
			rev_first     INT,
			rev_last      INT,
			src_path      TEXT,
			src_rev       INT
		)
	") or die $self->dbh()->errstr();

	$self->dbh()->do("
		CREATE INDEX dir_path_rev_active ON dir (path, rev_first, is_active)
	") or die $self->dbh()->errstr();

	$self->dbh()->do("
		CREATE INDEX dir_path_active ON dir (path, is_active)
	") or die $self->dbh()->errstr();

	$self->dbh()->do("
		CREATE INDEX dir_rev ON dir (rev_first)
	") or die $self->dbh()->errstr();

	$self->dbh()->do("
		CREATE INDEX dir_lop_relative ON dir (path_lop, rel_path)
	") or die $self->dbh()->errstr();

	# Copy sources.

	$self->dbh()->do("
		CREATE TABLE copy (
			seq       INTEGER PRIMARY KEY AUTOINCREMENT,
			src_path  TEXT,
			src_rev   INT,
			kind      TEXT,
			dst_path  TEXT,
			dst_rev   INT
		)
	") or die $self->dbh()->errstr();

	$self->dbh()->do("
		CREATE INDEX copy_srev ON copy (src_rev)
	") or die $self->dbh()->errstr();

	$self->dbh()->do("
		CREATE TABLE rev_map (
			seq       INTEGER PRIMARY KEY AUTOINCREMENT,
			svn_rev   INT,
			other_rev TEXT
		)
	") or die $self->dbh()->errstr();

	$self->dbh()->do("
		CREATE INDEX rev_map_svn ON rev_map (svn_rev, other_rev)
	") or die $self->dbh()->errstr();

	$self->dbh()->do("
		CREATE INDEX rev_map_other ON rev_map (other_rev, svn_rev)
	") or die $self->dbh()->errstr();
}

### Public entry points.

sub consider_add {
	my ($self, $path, $revision, $kind) = @_;

	warn "add: $path $revision" if $self->verbose();

	# Touch the parent directory of the thing being added.
	$self->_touch_parent_directory($path, $revision);

	# If this is a file, we're done.
	return if $kind ne "dir";

	# Adding a directory.  It shall not previously exist.
	confess "adding previously existing path $path at r$revision" if (
		$self->_path_exists($path, $revision)
	);

	# Add unconditionally.
	my $sth = $self->dbh()->prepare_cached("
		INSERT INTO dir (
			path, rev_first, rev_last, op_first, op_last,
			is_active, is_add, is_copy, is_modified
		)
		VALUES (
			?, ?, ?, ?, ?,
			?, ?, ?, ?
		)
	") or die $self->dbh()->errstr();

	warn "INSERT $path r$revision" if $self->verbose();
	$sth->execute($path, $revision, $revision, "add", "add", 1, 1, 0, 0) or die (
		$sth->errstr()
	);

	return;
}

sub consider_change {
	my ($self, $path, $revision, $kind) = @_;
	return $self->_touch_parent_directory($path, $revision) if $kind ne "dir";
	return $self->_touch_directory($path, $revision);
}

sub consider_copy {
	my ($self, $dst_path, $dst_rev, $kind, $src_path, $src_rev) = @_;

	my $sth_copy = $self->dbh()->prepare_cached("
		INSERT INTO copy (src_path, src_rev, kind, dst_path, dst_rev)
		VALUES (?, ?, ?, ?, ?)
	") or die $self->dbh()->errstr();

	$sth_copy->execute($src_path, $src_rev, $kind, $dst_path, $dst_rev) or die(
		$sth_copy->errstr()
	);

	# It would suck if the relocated path existed.
	confess "target path $dst_path exists at r$dst_rev" if (
		$self->_path_exists($dst_path, $dst_rev)
	);

	# Touch the directory where the copy is landing.
	$self->_touch_parent_directory($dst_path, $dst_rev);

	# If this is a file, we're done.
	return if $kind ne "dir";

	warn "copy: $src_path $src_rev > $dst_path $dst_rev" if (
		$self->verbose()
	);

	# Copy the source path and all the entire tree below.
	foreach my $path_to_copy ($self->_get_tree_paths($src_path, $src_rev)) {
		my $relocated_path = $path_to_copy;
		$relocated_path =~ s/^\Q$src_path\E(\/|$)/$dst_path$1/ or confess(
			"can't relocate $path_to_copy from $src_path to $dst_path"
		);

		warn "copy includes: $path_to_copy > $relocated_path" if $self->verbose();

		my $sth = $self->dbh()->prepare_cached("
			INSERT INTO dir (
				path, rev_first, rev_last, op_first, op_last,
				is_active, is_add, is_copy, is_modified,
				src_path, src_rev
			)
			VALUES (
				?, ?, ?, ?, ?,
				?, ?, ?, ?,
				?, ?
			)
		") or die $self->dbh()->errstr();

		my $is_add = ($path_to_copy eq $src_path) ? 1 : 0;

		$sth->execute(
			$relocated_path, $dst_rev, $dst_rev, "copy", "copy",
			1, $is_add, 1, 0,
			$path_to_copy, $src_rev,
		) or die $sth->errstr();
	}

	return;
}

sub consider_delete {
	my ($self, $path, $revision) = @_;

	# Touch the parent directory and all its ancestors back to the root.
	$self->_touch_parent_directory($path, $revision);

	# If the path doesn't exist, then we just deleted a file.
	# TODO - Or we deleted a defunct directory?
	return unless $self->_path_exists($path, $revision);

	# Otherwise flag the tree at the deletion point.
	foreach my $path_to_delete ($self->_get_tree_paths($path, $revision)) {

		# Double deletion is bad.
		confess "deleting nonexistent $path_to_delete at r$revision" unless (
			$self->_path_exists($path_to_delete, $revision)
		);

		warn "UPDATE $path $revision (is_active=0)" if $self->verbose();

		my $sth = $self->dbh()->prepare_cached("
			UPDATE dir SET rev_last = ?, op_last = ?, is_active = ?
			WHERE path = ? and rev_first <= ? and is_active = 1
		") or die $self->dbh()->errstr();

		$sth->execute(
			$revision, "delete", 0,
			$path_to_delete, $revision,
		);
	}

	return;
}

sub analyze {
	my $self = shift;

	# Sanity check.  Each path may have at most one active row.

	my $sth = $self->dbh()->prepare_cached("
		SELECT path, count(is_active) as ct
		FROM dir
		WHERE is_active = 1
		GROUP BY path
		HAVING ct > 1
	") or die $self->dbh()->errstr();

	$sth->execute() or die $sth->errstr();
	$sth->bind_columns(\my ($path, $count)) or die $sth->errstr();

	my $failures = 0;
	while ($sth->fetch()) {
		$failures++;
		warn "path $path has $count is_active rows";
	}
	die "only 1 is_active row allowed for any path" if $failures;

	# Normalize active directory final revisions.

	my $sth_set_final_rev = $self->dbh()->prepare_cached("
		UPDATE dir SET rev_last = (SELECT max(rev_last) from DIR)
		WHERE is_active = 1
	") or die $self->dbh()->errstr();

	$sth_set_final_rev->execute();
}

sub auto_tag {
	my ($self, $hint_generator) = @_;

	my $sth_iterator = $self->dbh()->prepare_cached("
		SELECT seq, path, rev_first, op_first, rev_last, op_last, is_modified
		FROM dir
	") or die $self->dbh()->errstr();

	$sth_iterator->execute() or die $sth_iterator->errstr();
	$sth_iterator->bind_columns(
		\my ($seq, $path, $rev_first, $op_first, $rev_last, $op_last, $is_modified)
	) or die $sth_iterator->errstr();

	while ($sth_iterator->fetch()) {
		my ($ent_type, $ent_name, $path_lop, $path_prepend) = $hint_generator->(
			$path, $rev_first, $op_first, $rev_last, $op_last, $is_modified
		);

		# A tag with changes is a branch.
		if ($ent_type eq "tag") {
			$ent_type = "branch" if $is_modified;
		}
		elsif ($ent_type eq "branch") {
			$ent_type = "tag" unless $is_modified;
		}

		# Calculate the relative path from the lop and prepend.
		my $rel_path = $path;
		$rel_path =~ s!^\Q$path_lop\E(?:/|$)!! if length $path_lop;
		$rel_path =~ s!^/*!$path_prepend/! if length $path_prepend;

		my $sth_update = $self->dbh()->prepare_cached("
			UPDATE dir
			SET
				ent_type = ?, ent_name = ?,
				path_lop = ?, path_prepend = ?, rel_path = ?
			WHERE seq = ?
		") or die $self->dbh()->errstr();

		$sth_update->execute(
			$ent_type, $ent_name, $path_lop, $path_prepend, $rel_path, $seq
		) or die $sth_update->errstr();
	}

	# Propagate entity root type,name tuples throughout their
	# subdirectories.

	my $sth_find_ent_roots = $self->dbh()->prepare_cached('
		SELECT path, ent_type, ent_name
		FROM dir
		WHERE path_lop != "" AND rel_path == ""
		ORDER BY
			length(path_lop) ASC, path_lop ASC, length(rel_path) ASC, rel_path ASC
	') or die $self->dbh()->errstr();

	$sth_find_ent_roots->execute() or die $sth_find_ent_roots->errstr();
	$sth_find_ent_roots->bind_columns(
		\my ($ent_path, $ent_type, $ent_name)
	) or die(
		$sth_find_ent_roots->errstr()
	);

	while ($sth_find_ent_roots->fetch()) {
		# First, ensure the entity doesn't contain sub-entities.
		# Nested entities aren't currently supported.
		#
		# TODO - However they ought to be if sub-entities are branches,
		# trunk and tags of a project.

		my $sth_find_sub_roots = $self->dbh()->prepare_cached('
			SELECT path
			FROM dir
			WHERE path LIKE ? AND path_lop != "" AND rel_path == ""
			ORDER BY length(path) ASC, path ASC
		') or die $self->dbh()->errstr();

		my $like_path = "$ent_path/%";
		$sth_find_sub_roots->execute($like_path) or die(
			$sth_find_sub_roots->errstr()
		);
		$sth_find_sub_roots->bind_columns(\my $broken_path) or die(
			$sth_find_sub_roots->errstr()
		);

		my $failures = 0;
		while ($sth_find_sub_roots->fetch()) {
			$failures++;
			warn "failure: entity at $ent_path contains sub-entity at $broken_path";
		}
		die "sub-entities indicate bad entity recognition" if $failures;

		# Second, ensure that the lop and prepend paths are consistent
		# throughout the tree.
		# TODO - Although this may be true as a corollary of rel_path
		# being nonzero length throughout the entity tree, so we're
		# skipping the check until we're sure it's necessary.

		# TODO - Code?

		# Okay, it's good.
		# Let's propagate its entity type and name throughout its tree.

		my $sth_update_entity = $self->dbh()->prepare_cached("
			UPDATE dir
			SET ent_type = ?, ent_name = ?
			WHERE path LIKE ?
		") or die $self->dbh()->errstr();

		$sth_update_entity->execute($ent_type, $ent_name, $like_path) or die(
			$sth_update_entity->errstr()
		);
	}
}

# Fix copy targets so their entity types match copy sources.
# Copies describe a set of directed graphs.  Each modified target
# directory may trigger a new fixup if it also describes a copy
# source.

sub fix_copy_targets {
	my $self = shift;

	my $sth_update_entity = $self->dbh()->prepare_cached("
		UPDATE dir
		SET ent_type = ?
		WHERE (path = ? OR path LIKE ?) AND rev_first <= ? AND rev_last > ?
	") or die $self->dbh()->errstr();

	my $sth_find_copies = $self->dbh()->prepare_cached("
		SELECT *
		FROM copy
		WHERE src_path = ? OR src_path LIKE ? OR dst_path = ? OR dst_path LIKE ?
	") or die $self->dbh()->errstr();

	my @pending_copies = $self->get_all_copies();
	while (@pending_copies) {
		my $next_copy = pop @pending_copies;

		# Get the source and destination dir info.
		my $src_info = $self->get_dir_info(
			$next_copy->src_path(),
			$next_copy->src_rev(),
		);

		# No point if source isn't an entity.
		next unless defined $src_info and $src_info->is_entity();

		my $dst_info = $self->get_dir_info(
			$next_copy->dst_path(),
			$next_copy->dst_rev(),
		);

		# Failure if destination isn't an entity.
		die(
			"illegal copy from ",
			$src_info->ent_type(), " ", $src_info->ent_name(),
			" to non-entity ", $dst_info->path()
		) unless defined $dst_info and $dst_info->is_entity();

		# We're good if the entities match.
		next if $src_info->ent_type() eq $dst_info->ent_type();

		# Otherwise the destination entity type must be modified to match
		# the source type.
		my $dst_ent_path  = $next_copy->dst_path();
		my $dst_like_path = "$dst_ent_path/%";

		$sth_update_entity->execute(
			$src_info->ent_type(),
			$dst_ent_path, $dst_like_path,
			$next_copy->dst_rev(), $next_copy->dst_rev(),
		) or die $sth_update_entity->errstr();

		# If the destination entity path describes copy sources, then put
		# those sources into the pending copies.
		$sth_find_copies->execute(
			$dst_ent_path, $dst_like_path, $dst_ent_path, $dst_like_path,
		) or die $sth_find_copies->errstr();

		while (my $copy_row = $sth_find_copies->fetchrow_hashref()) {
			push @pending_copies, SVN::Analysis::Copy->new($copy_row);
		}
	}
}

### snassign accessors

# Return the IDs of significant revisions, in order.
sub get_significant_revisions {
	my $self = shift;

	my $sth = $self->dbh()->prepare_cached("
		SELECT DISTINCT rev_first
		FROM dir
		WHERE is_add = 1
		ORDER BY rev_first
	") or die $self->dbh()->errstr();

	$sth->execute() or die $sth->errstr();
	$sth->bind_columns(\my $significant_rev) or die $sth->errstr();

	my @significant_revisions;
	push @significant_revisions, $significant_rev while $sth->fetch();

	return @significant_revisions;
}

# Return the repository at a specific revision as a tree.
sub get_tree {
	my ($self, $revision) = @_;

	my $tree = SVN::Analysis::TreeNode->new(
		children      => { },
		parent        => undef,

		seq           => 0,
		ent_name      => '',
		ent_type      => 'repository',
		is_add        => 0,
		is_copy       => 0,
		name          => "(repository)",
		path          => "",
		path_lop      => '',
		path_prepend  => '',
		rel_path      => '',
		revision      => 0,
		src_path      => "",
		src_rev       => 0,
	);

	my $sth_tree = $self->dbh()->prepare_cached("
		SELECT path, max(rev_first)
		FROM dir
		WHERE rev_first <= ? AND rev_last >= ?
		GROUP BY path
		ORDER BY length(path) ASC, path ASC
	") or die $self->dbh()->errstr();

	# Build a tree from the flat nodes.

	$sth_tree->execute($revision, $revision) or die $sth_tree->errstr();
	$sth_tree->bind_columns(\my ($path, $rev)) or die $sth_tree->errstr();

	while ($sth_tree->fetch()) {
		my $sth_node = $self->dbh()->prepare_cached("
			SELECT
				seq,
				is_active, is_add, is_copy, src_path, src_rev,
				ent_type, ent_name, rel_path, path_lop, path_prepend
			FROM dir
			WHERE path = ? AND rev_first = ?
			ORDER BY seq DESC
			LIMIT 1
		") or die $self->dbh()->errstr();

		$sth_node->execute($path, $rev) or die $sth_node->errstr();
		$sth_node->bind_columns(
			\my (
				$seq,
				$is_active, $is_add, $is_copy, $src_path, $src_rev,
				$ent_type, $ent_name, $rel_path, $path_lop, $path_prepend
			)
		) or die $sth_node->errstr();

		$sth_node->fetch() or die $sth_node->errstr();
		$sth_node->fetch() and die "more than one node for $path r$rev";

		# Traverse to the new node.

		my $iter = $tree;
		my @segments = split m!/!, $path;
		my $final = pop(@segments);
		foreach (@segments) {
			$iter = $iter->children()->{$_} or die(
				"segment $_ from $path r$rev not found"
			);
		}

		if (defined $final) {
			die "duplicate segment $final in $path r$rev" if exists(
				$iter->children()->{$final}
			);

			$iter->children()->{$final} = SVN::Analysis::TreeNode->new(
				seq           => $seq,
				path          => $path,
				name          => $final,
				revision      => $rev,
				is_copy       => $is_copy,
				is_add        => $is_add,
				src_path      => $src_path,
				src_rev       => $src_rev,
				children      => { },
				parent        => $iter,
				ent_type      => $ent_type,
				ent_name      => $ent_name,
				path_lop      => $path_lop,
				path_prepend  => $path_prepend,
				rel_path      => $rel_path,
			);
		}
		elsif ($iter != $tree) {
			die "wtf";
		}
	}

	return $tree;
}

# Return the copy sources for a given revision, or an empty list for
# none.

sub get_copy_sources_for_revision {
	my ($self, $revision) = @_;

	my $sth = $self->dbh()->prepare_cached("
		SELECT src_path, kind
		FROM copy
		WHERE src_rev = ?
	") or die $self->dbh()->errstr();

	$sth->execute($revision) or die $sth->errstr();
	$sth->bind_columns(\my ($src_path, $kind)) or die $sth->errstr();

	my @copy_sources;
	while ($sth->fetch()) {
		push @copy_sources, SVN::Analysis::Copy->new(
			src_path  => $src_path,
			kind      => $kind,
		);
	}

	return @copy_sources;
}

# Return all copy sources.
# TODO - Inefficient.  What's a better way?

sub get_all_copy_sources {
	my $self = shift;

	my $sth = $self->dbh()->prepare_cached("
		SELECT DISTINCT src_path, src_rev, kind
		FROM copy
	") or die $self->dbh()->errstr();

	$sth->execute() or die $sth->errstr();

	my @copy_sources;
	while (my $row = $sth->fetchrow_hashref()) {
		push @copy_sources, SVN::Analysis::Copy->new($row);
	}

	return @copy_sources;
}

sub get_all_copies {
	my $self = shift;

	my $sth = $self->dbh()->prepare_cached("SELECT * FROM copy") or die(
		$self->dbh()->errstr()
	);

	$sth->execute() or die $sth->errstr();

	my @copies;
	while (my $row = $sth->fetchrow_hashref()) {
		push @copies, SVN::Analysis::Copy->new($row);
	}

	return @copies;
}

sub get_all_copies_for_src {
	my ($self, $copy_source) = @_;

	my $sth = $self->dbh()->prepare_cached("
		SELECT *
		FROM copy
		WHERE src_path = ? AND src_rev = ?
	") or die $self->dbh()->errstr();

	$sth->execute($copy_source->src_path(), $copy_source->src_rev()) or die(
		$sth->errstr()
	);

	my @copies;
	while (my $copy_row = $sth->fetchrow_hashref()) {
		push @copies, SVN::Analysis::Copy->new($copy_row);
	}

	return @copies;
}

sub get_last_copy_into_tree {
	my ($self, $src_tree_path, $dst_tree_path) = @_;

	my $sth = $self->dbh()->prepare_cached("
		SELECT *
		FROM copy
		WHERE
			(src_path = ? OR src_path LIKE ?) AND
			(dst_path = ? OR dst_path LIKE ?)
		ORDER BY src_rev DESC
		LIMIT 1
	") or die $self->dbh()->errstr();

	my $src_like = "$src_tree_path/%";
	my $dst_like = "$dst_tree_path/%";

	$sth->execute(
		$src_tree_path, $src_like,
		$dst_tree_path, $dst_like,
	) or die $sth->errstr();

	my @copies;
	while (my $copy_row = $sth->fetchrow_hashref()) {
		push @copies, SVN::Analysis::Copy->new($copy_row);
	}

	return $copies[0];
}

#sub get_last_copy_out_of_tree {
#	my ($self, $tree_path) = @_;
#
#	my $sth = $self->dbh()->prepare_cached("
#		SELECT *
#		FROM copy
#		WHERE
#			(src_path = ? OR src_path LIKE ?) AND NOT
#			(dst_path = ? OR dst_path LIKE ?)
#		ORDER BY src_rev DESC
#		LIMIT 1
#	") or die $self->dbh()->errstr();
#
#	my $tree_like_path = "$tree_path/%";
#
#	$sth->execute(
#		$tree_path, $tree_like_path,
#		$tree_path, $tree_like_path,
#	) or die $sth->errstr();
#
#	my @copies;
#	while (my $copy_row = $sth->fetchrow_hashref()) {
#		push @copies, SVN::Analysis::Copy->new($copy_row);
#	}
#
#	return $copies[0];
#}

# Return the SVN::Analysis::Dir object that encapsulates a
# path,revision tuple.  Returns nothing on failure.

sub get_dir_info {
	my ($self, $path, $revision) = @_;

	# TODO - What if multiple rows match?
	my $sth = $self->dbh()->prepare_cached("
		SELECT * FROM dir
		WHERE path = ? AND rev_first <= ? AND rev_last >= ?
		ORDER BY seq DESC
		LIMIT 1
	") or die $self->dbh()->errstr();

	$sth->execute($path, $revision, $revision) or die $sth->errstr();
	my $row = $sth->fetchrow_hashref() or return;
	$sth->fetch() and die "$path $revision refers to too many dir rows";

	return SVN::Analysis::Dir->new($row);
}

sub ignore_copy {
	my ($self, $copy) = @_;
	
	my $sth = $self->dbh()->prepare_cached("
		DELETE FROM copy WHERE seq = ?
	") or die $self->dbh()->errstr();

	$sth->execute($copy->seq()) or die $sth->errstr();
}

### Internal utilities.

sub _touch_parent_directory {
	my ($self, $path, $revision) = @_;
	return unless length $path;
	$path =~ s!/*[^/]*/*$!!;
	$self->_touch_directory($path, $revision);
	return;
}

sub _touch_directory {
	my ($self, $path, $revision) = @_;

	foreach my $dir_path ($self->_get_container_paths($path, $revision)) {

		warn "touchdir: $dir_path $revision" if $self->verbose();

		my $sth_query = $self->dbh()->prepare_cached("
			SELECT op_last, rev_first
			FROM dir
			WHERE path = ? AND rev_first <= ? AND is_active = 1
			ORDER BY path DESC, rev_first DESC
			LIMIT 1
		") or die $self->dbh()->errstr();

		$sth_query->execute($path, $revision) or die(
			$sth_query->errstr()
		);

		$sth_query->bind_columns(\my ($last_op, $rev_first)) or die(
			$sth_query->errstr()
		);

		$sth_query->fetch() or die $sth_query->errstr();
		$sth_query->fetch() and die(
			"more than one active row for $path r$revision"
		);

		warn "UPDATE $dir_path $rev_first -> $revision" if $self->verbose();

		my $sth_update = $self->dbh()->prepare_cached("
			UPDATE dir
			SET op_last = ?, rev_last = ?, is_modified = 1
			WHERE path = ? AND rev_first = ? AND is_active = 1
		") or die $self->dbh()->errstr();

		$sth_update->execute("touch", $revision, $dir_path, $rev_first) or die(
			$sth_update->errstr()
		);
	}

	return;
}

sub _get_container_paths {
	my ($self, $path, $revision) = @_;

	my @paths;

	my $shrinking_path = $path;
	while (length $shrinking_path) {
		confess "$shrinking_path not a container of $path at $revision" unless (
			$self->_path_exists($shrinking_path, $revision)
		);

		push @paths, $shrinking_path;
		$shrinking_path =~ s!/*[^/]*/*$!!;
	}

	# The empty root directory also counts.
	push @paths, "";

	return @paths;
}

sub _path_exists {
	my ($self, $path, $revision) = @_;

	my $sth = $self->dbh()->prepare_cached("
		SELECT count(rev_first) as ct
		FROM dir
		WHERE path = ? AND rev_first <= ? AND is_active = 1
		ORDER BY path DESC, rev_first DESC
	") or die $self->dbh()->errstr();

	$sth->execute($path, $revision) or die $sth->errstr();

	my $exists = 0;
	$sth->bind_columns(\$exists) or die $sth->errstr();

	$sth->fetch();
die "$path r$revision exists more than once" if $exists > 1;
	$sth->fetch() and die "more than one active row for $path r$revision";

	return $exists;
}

sub _get_tree_paths {
	my ($self, $path, $revision) = @_;

	my $sth = $self->dbh()->prepare_cached("
		SELECT path, rev_first
		FROM dir
		WHERE (path = ? OR path LIKE ?) AND rev_first <= ? AND is_active = 1
		ORDER BY length(path) DESC, path ASC
	") or die $self->dbh()->errstr();

	(my $partial_path = $path) =~ s!/*$!/%!;

	$sth->execute($path, $partial_path, $revision) or die $sth->errstr();

	$sth->bind_columns(\my ($found_path, $found_rev)) or die $sth->errstr();

	my @found_paths;
	while ($sth->fetch()) {
		warn "... $path = $found_path ($found_rev)" if $self->verbose();
		push @found_paths, $found_path;
	}

	return @found_paths;
}

sub map_revisions {
	my ($self, $svn_revision, $other_revision) = @_;

	my $sth = $self->dbh()->prepare_cached("
		INSERT INTO rev_map (svn_rev, other_rev)
		VALUES (?, ?)
	") or die $self->dbh()->errstr();

	$sth->execute($svn_revision, $other_revision) or die $sth->errstr();
}

sub get_other_rev_from_svn {
	my ($self, $svn_revision) = @_;

	my $sth = $self->dbh()->prepare_cached("
		SELECT other_rev
		FROM rev_map
		WHERE svn_rev = ?
		ORDER BY svn_rev
	") or die $self->dbh()->errstr();

	$sth->execute($svn_revision) or die $sth->errstr();

	$sth->bind_columns(\my $other_revision) or die $sth->errstr();

	my @other_revisions;
	while ($sth->fetch()) {
		push @other_revisions, $other_revision;
	}

	return @other_revisions if wantarray;
	croak "too many revisions for scalar context" if @other_revisions > 1;
	return $other_revisions[0];
}

1;
