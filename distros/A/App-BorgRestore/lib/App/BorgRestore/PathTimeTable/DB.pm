package App::BorgRestore::PathTimeTable::DB;
use strictures 2;

use Function::Parameters;
BEGIN {
	use Log::Any qw($log);
	# Trace logging statements are disabled here since they incur a performance
	# overhead because they are in tight loops. This block only works for the
	# test suite code (set env var TAP_LOG_FILTER=none) since the normal
	# application only changes the log level at run time. Hardcode to 1 when
	# necessary (or write a test!).
	use constant TRACE => $log->is_trace;
}

=head1 NAME

App::BorgRestore::PathTimeTable::DB - Directly write new archive data to the database

=head1 DESCRIPTION

This is used by L<App::BorgRestore> to add new archive data into the database.
Data is written to the database directly and existing data is updated where necessary.

For performance reasons this class keeps an internal cache so that the database
is only contacted when necessary. The cache assumes that the path are sorted so
that all files from one directory are added, before files from another. If a
path from a different directory is added, the previous cache is invalidated.
Upon invalidation the time stamp is written to the database. If paths are
properly sorted, this results in only a single database write for each path.

=cut


method new($class: $deps = {}) {
	return $class->new_no_defaults($deps);
}

method new_no_defaults($class: $deps = {}) {
	my $self = {};
	bless $self, $class;
	$self->{deps} = $deps;
	$self->{cache} = {};
	$self->{current_path_in_cache} = "";
	$self->{stats} = {};
	return $self;
}

method set_archive_id($archive_id) {
	$self->{archive_id} = $archive_id;
}

method add_path($path, $time) {
	$log->tracef("Adding path to cache: %s", $path) if TRACE;
	$self->{stats}->{total_paths}++;
	my $old_cache_path = $self->{current_path_in_cache};
	# Check if the new path requires us to (partially) invalidate our cache and
	# add any files/directories to the database. If the new path is a subpath
	# (substring actually) of the cached path, we can keep it only in the cache
	# and no flush is needed. Otherwise we need to flush all parts of the path
	# that are no longer contained in the new path.
	#
	# We start by checking the currently cached path ($old_cache_path) against
	# the new $path. Then we remove one part from the path at a time, until we
	# reach a parent path (directory) of $path.
	$log->tracef("Checking if cache invalidation is required") if TRACE;
	while ((my $slash_index = rindex($old_cache_path, "/")) != -1) {
		$self->{stats}->{cache_invalidation_loop_iterations}++;
		# Directories in the borg output cannot be differentiated by their
		# path, since their path looks just like a file path. I.e. there is no
		# directory separator (/) at the end of a directory path.
		#
		# Since we want to keep any directory in our cache, if it contains
		# $path, we can treat any cached path as a directory path. If the
		# cached path was really a directory, the new $path will also contain a
		# directory separator (/) between the old cached path (the parent
		# directory) and the new path (a subdirectory or a file in the
		# directory). If the cached path was not actually a directory,
		# but a file, the new path cannot match the old one because a file name
		# cannot contain a directory separator.
		my $cache_check_path = $old_cache_path.'/';
		$log->tracef("Checking if cached path '%s' contains '%s'", $cache_check_path, $path) if TRACE;
		if ($cache_check_path eq substr($path, 0, length($cache_check_path))) {
			$log->tracef("Cache path '%s' is a parent directory of new path '%s'", $old_cache_path, $path) if TRACE;
			# keep the cache content for the part of the path that stays the same
			last;
		}
		$log->tracef("Cached path '%s' requires flush to database", $old_cache_path) if TRACE;
		my $removed_time = delete $self->{cache}->{$old_cache_path};
		$self->_add_path_to_db($self->{archive_id}, $old_cache_path, $removed_time);
		# strip last part of path
		$old_cache_path = substr($old_cache_path, 0, $slash_index);
		$log->tracef("Changed cache path to parent directory: %s", $old_cache_path) if TRACE;

		# update parent timestamp
		my $cached = $self->{cache}->{$old_cache_path};
		if (!defined $cached || $cached < $removed_time) {
			$log->tracef("Setting cache time for path '%s' to %d", $old_cache_path, $removed_time) if TRACE;
			$self->{cache}->{$old_cache_path} = $removed_time;
		}
	}
	$log->tracef("Cache invalidation complete") if TRACE;

	my $cache_check_path = $old_cache_path.'/';
	if ($cache_check_path ne substr($path, 0, length($cache_check_path))) {
		# ensure that top level directory is also written
		$self->_add_path_to_db($self->{archive_id}, $old_cache_path, $self->{cache}->{$old_cache_path}) unless ($old_cache_path eq "." or $old_cache_path eq '');
	}

	my $cached = $self->{cache}->{$path};
	if (!defined $cached || $cached < $time) {
		$log->tracef("Setting cache time for path '%s' to %d", $path, $time) if TRACE;
		$self->{cache}->{$path} = $time;
	}
	$self->{current_path_in_cache} = $path;
}

method _add_path_to_db($archive_id, $path,$time) {
	my $cached = $self->{cache}->{$path};
	$self->{stats}->{total_potential_calls_to_db_class}++;
	$log->tracef("Updating DB for path '%s' with time %d", $path, $time) if TRACE;
	$self->{stats}->{real_calls_to_db_class}++;
	$self->{deps}->{db}->update_path_if_greater($archive_id, $path, $time);
}


method save_nodes() {
	# flush remaining paths to the DB
	$self->add_path(".", 0);

	for my $key (keys %{$self->{stats}}) {
		$log->debugf("Performance counter %s = %s", $key, $self->{stats}->{$key});
	}
}

1;

__END__
