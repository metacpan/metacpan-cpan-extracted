package App::BorgRestore;
use v5.10;
use strict;
use warnings;

our $VERSION = "2.0.1";

use App::BorgRestore::Borg;
use App::BorgRestore::DB;
use App::BorgRestore::Helper;
use App::BorgRestore::Settings;

use autodie;
use Carp;
use Cwd qw(abs_path getcwd);
use File::Basename;
use File::Spec;
use File::Temp;
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

method new($class: $deps = {}) {
	my $self = {};
	bless $self, $class;

	my $db_path = App::BorgRestore::Settings::get_db_path();
	my $cache_size = $App::BorgRestore::Settings::sqlite_cache_size;

	$self->{borg} = $deps->{borg} // App::BorgRestore::Borg->new($App::BorgRestore::Settings::borg_repo);
	$self->{db} = $deps->{db} // App::BorgRestore::DB->new($db_path, $cache_size);

	return $self;
}

method new_no_defaults($class: $deps) {
	my $self = {};
	bless $self, $class;

	$self->{borg} = $deps->{borg};
	$self->{db} = $deps->{db};

	return $self;
}

method resolve_relative_path($path) {
	my $canon_path = File::Spec->canonpath($path);
	my $abs_path = abs_path($canon_path);

	if (!defined($abs_path)) {
		$log->errorf("Failed to resolve path to absolute path: %s: %s", $canon_path, $!);
		$log->error("Make sure that all parts of the path, except the last one, exist.");
		die "Path resolving failed\n";
	}

	return $abs_path;
}

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
		$log->errorf("Path '%s' not found in any archive.\n", $path);
		die "Failed to find archives for path\n";
	}

	@ret = sort { $a->{modification_time} <=> $b->{modification_time} } @ret;

	return \@ret;
}

method get_all_archives() {
	#my %seen_modtime;
	my @ret;

	$log->debugf("Fetching list of all archives");

	my $archives = $self->{borg}->borg_list_time();

	for my $archive (@$archives) {
		push @ret, $archive;
	}

	if (!@ret) {
		$log->errorf("No archives found.\n");
		die "No archives found.\n";
	}

	@ret = sort { $a->{modification_time} <=> $b->{modification_time} } @ret;

	return \@ret;
}

method select_archive_timespec($archives, $timespec) {
	my $seconds = $self->_timespec_to_seconds($timespec);
	if (!defined($seconds)) {
		$log->errorf("Invalid time specification: %s", $timespec);
		croak "Invalid time specification";
	}

	my $target_timestamp = time - $seconds;

	$log->debugf("Searching for newest archive that contains a copy before %s", App::BorgRestore::Helper::format_timestamp($target_timestamp));

	for my $archive (reverse @$archives) {
		if ($archive->{modification_time} < $target_timestamp) {
			$log->debugf("Found archive with timestamp %s", App::BorgRestore::Helper::format_timestamp($archive->{modification_time}));
			return $archive;
		}
	}

	die "Failed to find archive matching time specification\n";
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

method restore($path, $archive, $destination) {
	$destination = App::BorgRestore::Helper::untaint($destination, qr(.*));
	$path = App::BorgRestore::Helper::untaint($path, qr(.*));
	my $archive_name = App::BorgRestore::Helper::untaint_archive_name($archive->{archive});

	$log->infof("Restoring %s to %s from archive %s", $path, $destination, $archive->{archive});

	my $basename = basename($path);
	my $components_to_strip =()= $path =~ /\//g;

	$log->debugf("CWD is %s", getcwd());
	$log->debugf("Changing CWD to %s", $destination);
	mkdir($destination) unless -d $destination;
	chdir($destination) or die "Failed to chdir: $!";
	# TODO chdir back to original after restore

	my $final_destination = abs_path($basename);
	$final_destination = App::BorgRestore::Helper::untaint($final_destination, qr(.*));
	$log->debugf("Removing %s", $final_destination);
	File::Path::remove_tree($final_destination);
	$self->{borg}->restore($components_to_strip, $archive_name, $path);
}

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
			$log->debugf("Removing archive %s", $archive);
			$self->{db}->begin_work;
			$self->{db}->remove_archive($archive);
			$self->{db}->commit;
			$self->{db}->vacuum;
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

		$log->debugf("Adding archive %s", $archive);

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

method update_cache() {
	$log->debug("Updating cache if required");

	my $borg_archives = $self->{borg}->borg_list();

	$self->_handle_removed_archives($borg_archives);
	$self->_handle_added_archives($borg_archives);

	$log->debugf("DB contains information for %d archives in %d rows", scalar(@{$self->{db}->get_archive_names()}), $self->{db}->get_archive_row_count());
}


1;
__END__
