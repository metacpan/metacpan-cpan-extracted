package App::BorgRestore;
use v5.14;
use strict;
use warnings;

our $VERSION = "3.1.0";

use App::BorgRestore::Borg;
use App::BorgRestore::DB;
use App::BorgRestore::Helper;
use App::BorgRestore::Settings;

use autodie;
use Carp;
use Cwd qw(abs_path getcwd);
use Path::Tiny;
use File::pushd;
use Function::Parameters;
use Getopt::Long;
use List::Util qw(any all);
use Log::Any qw($log);
use Pod::Usage;
use POSIX ();
use Time::HiRes;

=encoding utf-8

=head1 NAME

App::BorgRestore - Restore paths from borg backups

=head1 SYNOPSIS

    use App::BorgRestore;

    my $app = App::BorgRestore->new();

    # Update the cache (call after creating/removing backups)
    $app->update_cache();

    # Restore a path from a backup that is at least 5 days old. Optionally
    # restore it to a different directory than the original.
    # Look at the implementation of this method if you want to know how the
    # other parts of this module work together.
    $app->restore_simple($path, "5days", $optional_destination_directory);

=head1 DESCRIPTION

App::BorgRestore is a restoration helper for borg.

It maintains a cache of borg backup contents (path and latest modification
time) and allows to quickly look up backups that contain a path. It further
supports restoring a path from an archive. The archive to be used can also be
automatically determined based on the age of the path.

The cache has to be updated regularly, ideally after creating or removing
backups.

L<borg-restore.pl> is a wrapper around this class that allows for simple CLI
usage.

This package uses L<Log::Any> for logging.

=head1 METHODS

=head2 Constructors

=head3 new

 App::BorgRestore->new(\%deps);

Returns a new instance. The following dependencies can be injected:

=over

=item * borg (optional)

This object is used to interact with the borg repository of the system.
Defaults to L<App::BorgRestore::Borg>

=item * db (optional)

This object is used to store the extracted data (the cache). Defaults to
L<App::BorgRestore::DB>

=back

=cut

method new($class: $deps = {}) {
	my $self = {};
	bless $self, $class;

	my $db_path = App::BorgRestore::Settings::get_db_path();
	my $cache_size = $App::BorgRestore::Settings::sqlite_cache_size;

	$self->{borg} = $deps->{borg} // App::BorgRestore::Borg->new($App::BorgRestore::Settings::borg_repo);
	$self->{db} = $deps->{db} // App::BorgRestore::DB->new($db_path, $cache_size);

	return $self;
}

=head3 new_no_defaults

Same as C<new> except that this does not initialize unset dependencies with
their default values. This is probably only useful for tests.

=cut

method new_no_defaults($class: $deps) {
	my $self = {};
	bless $self, $class;

	$self->{borg} = $deps->{borg};
	$self->{db} = $deps->{db};

	return $self;
}

=head2 Public Methods

=head3 resolve_relative_path

 my $abs_path = $app->resolve_relative_path($path);

Returns an absolute path for a given path.

=cut

method resolve_relative_path($path) {
	my $canon_path = path($path)->canonpath;
	my $abs_path = abs_path($canon_path);

	if (!defined($abs_path)) {
		$log->errorf("Failed to resolve path to absolute path: %s: %s", $canon_path, $!);
		$log->error("Make sure that all parts of the path, except the last one, exist.");
		die "Path resolving failed\n";
	}

	return $abs_path;
}

=head3 map_path_to_backup_path

 my $path_in_backup = $app->map_path_to_backup_path($abs_path);

Maps an absolute path from the system to the path that needs to be looked up in
/ extracted from the backup using C<@backup_prefixes> from
L<App::BorgRestore::Settings>.

Returns the mapped path (string).

=cut

method map_path_to_backup_path($abs_path) {
	my $backup_path = $abs_path;

	for my $backup_prefix (@App::BorgRestore::Settings::backup_prefixes) {
		if ($backup_path =~ m/$backup_prefix->{regex}/) {
			$backup_path =~ s/$backup_prefix->{regex}/$backup_prefix->{replacement}/;
			last;
		}
	}

	return $backup_path;
}

=head3 find_archives

 my $archives = $app->find_archives($path);

Returns an arrayref of archives (hash with "modification_time" and "archive")
from the database that contain a path.  Duplicates are filtered based on the
modification time of the path in the
archives.

=cut

method find_archives($path) {
	my %seen_modtime;
	my @ret;

	$log->debugf("Searching for archives containing '%s'", $path);

	my $archives = $self->{db}->get_archives_for_path($path);

	for my $archive (@$archives) {
		my $modtime = $archive->{modification_time};

		if (defined($modtime) && (!$seen_modtime{$modtime}++)) {
			push @ret, $archive;
		}
	}

	if (!@ret) {
		die $log->errorf("Path '%s' not found in any archive.", $path)."\n";
	}

	@ret = sort { $a->{modification_time} <=> $b->{modification_time} } @ret;

	return \@ret;
}

=head3 get_all_archives

 my $archives = $app->get_all_archives();

Returns an arrayref of archives (hash with "modification_time" and "archive")
from borg directly. This does not require the database to be populated. Instead
it just fetches a list of archives from borg at runtime and returns it.

The returned data structure is the same as that returned by C<find_archives>.

=cut

method get_all_archives() {
	my @ret;

	$log->debugf("Fetching list of all archives");

	my $archives = $self->{borg}->borg_list_time();

	for my $archive (@$archives) {
		push @ret, $archive;
	}

	if (!@ret) {
		die $log->error("No archives found.")."\n";
	}

	@ret = sort { $a->{modification_time} <=> $b->{modification_time} } @ret;

	return \@ret;
}

=head3 cache_contains_data

 if ($app->cache_contains_data()) { ... }

Returns 1 if the cache contains any archive data, 0 otherwise.

=cut

method cache_contains_data() {
	my $existing_archives = $self->{db}->get_archive_names();
	return @{$existing_archives}+0 > 0 ? 1 : 0;
}

=head3 select_archive_timespec

 my $archive = $app->select_archive_timespec($archives, $timespec);

Returns one archive from C<$archives> that is older than the value of
C<$timespec>.

I<timespec> is a string of the form "<I<number>><I<unit>>" with I<unit> being one of the following:
s (seconds), min (minutes), h (hours), d (days), m (months = 31 days), y (year). Example: "5.5d"

=cut

method select_archive_timespec($archives, $timespec) {
	my $seconds = $self->_timespec_to_seconds($timespec);
	if (!defined($seconds)) {
		croak $log->errorf("Invalid time specification: %s", $timespec);
	}

	my $target_timestamp = time - $seconds;

	$log->debugf("Searching for newest archive that contains a copy before %s", App::BorgRestore::Helper::format_timestamp($target_timestamp));

	for my $archive (reverse @$archives) {
		if ($archive->{modification_time} < $target_timestamp) {
			$log->debugf("Found archive with timestamp %s", App::BorgRestore::Helper::format_timestamp($archive->{modification_time}));
			return $archive;
		}
	}

	die $log->error("Failed to find archive matching time specification")."\n";
}

method _timespec_to_seconds($timespec) {
	if ($timespec =~ m/^(?>(?<value>[0-9.]+))(?>(?<unit>[a-z]+))$/) {
		my $value = $+{value};
		my $unit = $+{unit};

		my %factors = (
			s       => 1,
			second  => 1,
			seconds => 1,
			minute  => 60,
			minutes => 60,
			h       => 60*60,
			hour    => 60*60,
			hours   => 60*60,
			d       => 60*60*24,
			day     => 60*60*24,
			days    => 60*60*24,
			m       => 60*60*24*31,
			month   => 60*60*24*31,
			months  => 60*60*24*31,
			y       => 60*60*24*365,
			year    => 60*60*24*365,
			years   => 60*60*24*365,
		);

		if (exists($factors{$unit})) {
			return $value * $factors{$unit};
		}
	}

	return;
}

=head3 restore

 $app->restore($backup_path, $archive, $destination);

Restore a backup path (returned by C<map_path_to_backup_path>) from an archive
(returned by C<find_archives> or C<get_all_archives>) to a destination
directory.

If the destination path (C<$destination/$last_elem_of_backup_path>) exists, it
is removed before beginning extraction from the backup.

Warning: This method temporarily modifies the current working directory of the
process during method execution since this is required by C<`borg extract`>.

=cut

method restore($path, $archive, $destination) {
	$destination = App::BorgRestore::Helper::untaint($destination, qr(.*));
	$path = App::BorgRestore::Helper::untaint($path, qr(.*));
	my $archive_name = App::BorgRestore::Helper::untaint_archive_name($archive->{archive});

	$log->infof("Restoring %s to %s from archive %s", $path, $destination, $archive->{archive});

	my $basename = path($path)->basename;
	my $components_to_strip =()= $path =~ /\//g;

	$log->debugf("CWD is %s", getcwd());
	{
		$log->debugf("Changing CWD to %s", $destination);
		mkdir($destination) unless -d $destination;
		my $workdir = pushd($destination, {untaint_pattern => qr{^(.*)$}});

		my $final_destination = abs_path($basename);
		$final_destination = App::BorgRestore::Helper::untaint($final_destination, qr(.*));
		$log->debugf("Removing %s", $final_destination);
		File::Path::remove_tree($final_destination);
		$self->{borg}->restore($components_to_strip, $archive_name, $path);
	}
	$log->debugf("CWD is %s", getcwd());
}

=head3 restore_simple

 $app->restore_simple($path, $timespec, $destination);

Restores a C<$path> based on a C<$timespec> to an optional C<$destination>. If
C<$destination> is not specified, it is set to the parent directory of C<$path>
so that C<$path> is restored to its original place.

Refer to L</"select_archive_timespec"> for an explanation of the C<$timespec>
variable.

=cut

method restore_simple($path, $timespec, $destination) {
	my $abs_path = $self->resolve_relative_path($path);
	my $backup_path = $self->map_path_to_backup_path($abs_path);

	$destination //= dirname($abs_path);

	my $archives = $self->find_archives($backup_path);
	my $selected_archive = $self->select_archive_timespec($archives, $timespec);
	$self->restore($backup_path, $selected_archive, $destination);
}

method _add_path_to_hash($hash, $path, $time) {
	my @components = split /\//, $path;

	my $node = $hash;

	if ($path eq ".") {
		if ($time > $$node[1]) {
			$$node[1] = $time;
		}
		return;
	}

	# each node is an arrayref of the format [$hashref_of_children, $mtime]
	# $hashref_of_children is undef if there are no children
	for my $component (@components) {
		if (!defined($$node[0]->{$component})) {
			$$node[0]->{$component} = [undef, $time];
		}
		# update mtime per child
		if ($time > $$node[1]) {
			$$node[1] = $time;
		}
		$node = $$node[0]->{$component};
	}
}

=head3 search_path

 my $paths = $app->search_path($pattern)

Returns a arrayref of paths that match the pattern. The pattern is matched as
an sqlite LIKE pattern. If no % occurs in the pattern, the patterns is
automatically wrapped between two % so it may match anywhere in the path.

=cut

method search_path($pattern) {
	$pattern = '%'.$pattern.'%' if $pattern !~ m/%/;
	return $self->{db}->search_path($pattern);
}

=head3 get_missing_items

 my $items = $app->get_missing_items($have, $want);

Returns an arrayref of items that are part of C<$want>, but not of C<$have>.

=cut

method get_missing_items($have, $want) {
	my $ret = [];

	for my $item (@$want) {
		my $exists = any { $_ eq $item } @$have;
		push @$ret, $item if not $exists;
	}

	return $ret;
}

method _handle_removed_archives($borg_archives) {
	my $start = Time::HiRes::gettimeofday();

	my $existing_archives = $self->{db}->get_archive_names();

	# TODO this name is slightly confusing, but it works as expected and
	# returns elements that are in the previous list, but missing in the new
	# one
	my $remove_archives = $self->get_missing_items($borg_archives, $existing_archives);

	if (@$remove_archives) {
		for my $archive (@$remove_archives) {
			$log->infof("Removing archive %s", $archive);
			$self->{db}->begin_work;
			$self->{db}->remove_archive($archive);
			$self->{db}->commit;
			$self->{db}->vacuum;
			$self->{db}->verify_cache_fill_rate_ok();
		}

		my $end = Time::HiRes::gettimeofday();
		$log->debugf("Removing archives finished after: %.5fs", $end - $start);
	}
}

method _handle_added_archives($borg_archives) {
	my $archives = $self->{db}->get_archive_names();
	my $add_archives = $self->get_missing_items($archives, $borg_archives);

	for my $archive (@$add_archives) {
		my $start = Time::HiRes::gettimeofday();
		my $lookuptable = [{}, 0];

		$log->infof("Adding archive %s", $archive);

		$self->{borg}->list_archive($archive, sub {
			my $line = shift;
			# roll our own parsing of timestamps for speed since we will be parsing
			# a huge number of lines here
			# XXX: this also exists in BorgRestore::Helper::parse_borg_time()
			# example timestamp: "Wed, 2016-01-27 10:31:59"
			if ($line =~ m/^.{4} (?<year>....)-(?<month>..)-(?<day>..) (?<hour>..):(?<minute>..):(?<second>..) (?<path>.+)$/) {
				my $time = POSIX::mktime($+{second},$+{minute},$+{hour},$+{day},$+{month}-1,$+{year}-1900);
				#$log->debugf("Adding path %s with time %s", $+{path}, $time);
				$self->_add_path_to_hash($lookuptable, $+{path}, $time);
			}
		});

		my $borg_time = Time::HiRes::gettimeofday;

		$self->{db}->begin_work;
		$self->{db}->add_archive_name($archive);
		my $archive_id = $self->{db}->get_archive_id($archive);
		$self->_save_node($archive_id,  undef, $lookuptable);
		$self->{db}->commit;
		$self->{db}->vacuum;
		$self->{db}->verify_cache_fill_rate_ok();

		my $end = Time::HiRes::gettimeofday();
		$log->debugf("Adding archive finished after: %.5fs (parsing borg output took %.5fs)", $end - $start, $borg_time - $start);
	}
}

method _save_node($archive_id, $prefix, $node) {
	for my $child (keys %{$$node[0]}) {
		my $path;
		$path = $prefix."/" if defined($prefix);
		$path .= $child;

		my $time = $$node[0]->{$child}[1];
		$self->{db}->add_path($archive_id, $path, $time);

		$self->_save_node($archive_id, $path, $$node[0]->{$child});
	}
}


=head3 update_cache

 $app->update_cache();

Updates the database used by e.g. C<find_archives>.

=cut

method update_cache() {
	my $v2_basedir = App::BorgRestore::Settings::get_cache_base_dir_path("v2");
	if (-e $v2_basedir) {
		$log->info("Removing old v2 cache directory: $v2_basedir");
		path($v2_basedir)->remove_tree;
	}

	$log->debug("Updating cache if required");

	my $borg_archives = $self->{borg}->borg_list();

	# write operations benefit from the large cache so set the cache size here
	$self->{db}->set_cache_size();
	$self->_handle_removed_archives($borg_archives);
	$self->_handle_added_archives($borg_archives);

	$log->debugf("DB contains information for %d archives in %d rows", scalar(@{$self->{db}->get_archive_names()}), $self->{db}->get_archive_row_count());
	$self->{db}->verify_cache_fill_rate_ok();
}


1;
__END__

=head1 LICENSE

Copyright (C) 2016-2017  Florian Pritz E<lt>bluewind@xinu.atE<gt>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

See LICENSE for the full license text.

=head1 AUTHOR

Florian Pritz E<lt>bluewind@xinu.atE<gt>

=cut
