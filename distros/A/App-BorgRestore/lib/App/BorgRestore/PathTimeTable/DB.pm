package App::BorgRestore::PathTimeTable::DB;
use strictures 2;

use Function::Parameters;
use Log::Any qw($log);

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

# Trace logging statements are disabled here since they incur a performance
# overhead because they are in tight loops. Change to 1 when necessary.
use constant TRACE => 0;

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
	$self->{stats}->{total_paths}++;
	my $old_cache_path = $self->{current_path_in_cache};
	while ((my $slash_index = rindex($old_cache_path, "/")) != -1) {
		$self->{stats}->{cache_invalidation_loop_iterations}++;
		if ($old_cache_path eq substr($path, 0, length($old_cache_path))) {
			# keep the cache content for the part of the path that stays the same
			last;
		}
		my $removed_time = delete $self->{cache}->{$old_cache_path};
		$self->_add_path_to_db($self->{archive_id}, $old_cache_path, $removed_time);
		# strip last part of path
		$old_cache_path = substr($old_cache_path, 0, $slash_index);

		# update parent timestamp
		my $cached = $self->{cache}->{$old_cache_path};
		if (!defined $cached || $cached < $removed_time) {
			$log->tracef("Setting cache time for path '%s' to %d", $old_cache_path, $removed_time) if TRACE;
			$self->{cache}->{$old_cache_path} = $removed_time;
		}
	}

	if ($old_cache_path ne substr($path, 0, length($old_cache_path))) {
		# ensure that top level directory is also written
		$self->_add_path_to_db($self->{archive_id}, $old_cache_path, $self->{cache}->{$old_cache_path}) unless $old_cache_path eq ".";
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
