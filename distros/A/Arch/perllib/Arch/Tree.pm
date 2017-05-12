# Arch Perl library, Copyright (C) 2004-2005 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use 5.005;
use strict;

package Arch::Tree;

use Arch::Util qw(run_tla load_file _parse_revision_descs adjacent_revision);
use Arch::Backend qw(
	is_baz has_tree_version_dir_opt has_tree_id_cmd has_set_tree_version_cmd
	has_file_diffs_cmd has_commit_version_arg has_commit_files_separator
);
use Arch::Session;
use Arch::Name;
use Arch::Log;
use Arch::Inventory;
use Arch::Changes qw(:type);
use Arch::Changeset;

use Cwd;

sub new ($;$%) {
	my $class = shift;
	my $dir = shift || ".";
	die "No tree dir $dir\n" unless -d $dir;
	my ($root) = run_tla("tree-root", $dir);
	die "No tree root for dir $dir\n" unless $root;
	my %init = @_;

	my $self = {
		dir => $root,
		own_logs => $init{own_logs},
		hide_ids => $init{hide_ids},
		cache_logs => $init{cache_logs},
	};

	bless $self, $class;
	$self->clear_cache;
	return $self;
}

sub root ($) {
	my $self = shift;

	return $self->{dir};
}

sub get_id_tagging_method ($) {
	my $self = shift;

	($self->{id_tagging_method}) = run_tla("id-tagging-method", "-d", $self->{dir})
		unless $self->{id_tagging_method};

	return $self->{id_tagging_method};
}

sub get_version ($) {
	my $self = shift;
	return $self->{version} if $self->{version};
	my @add_params = has_tree_version_dir_opt()? ("-d"): ();
	my ($version) = run_tla("tree-version", @add_params, $self->{dir});
	return $self->{version} = $version;
}

sub get_revision ($) {
	my $self = shift;
	#return $self->{revision} if $self->{revision};
	my $cmd = has_tree_id_cmd()? "tree-id": "logs -frd";
	my ($revision) = run_tla($cmd, $self->{dir});
	return $self->{revision} = $revision;
}

sub set_version ($$) {
	my $self = shift;
	my $version = shift;

	delete $self->{version};
	my $cmd = has_set_tree_version_cmd()? "set-tree-version": "tree-version";
	run_tla($cmd, "-d", $self->{dir}, $version);

	return $?;
}

sub get_log_versions ($) {
	my $self = shift;
	my @versions = run_tla("log-versions", "-d", $self->{dir});
	return wantarray? @versions: \@versions;
}

sub add_log_version ($$) {
	my $self = shift;
	my $version = shift;

	run_tla("add-log-version", "-d", $self->{dir}, $version);

	return $?;
}

sub get_log_revisions ($;$) {
	my $self = shift;
	my $version = shift || $self->get_version;
	$version =~ s!-(SOURCE|MIRROR)/!/!;
	my @revisions = run_tla("logs", "-f", "-d", $self->{dir}, $version);
	return wantarray? @revisions: \@revisions;
}

sub get_log ($$) {
	my $self = shift;
	my $revision = shift || die;

	return $self->{cached_logs}->{$revision}
		if $self->{cached_logs}->{$revision};

	my $message;
	if ($self->{own_logs}) {
		my $name = Arch::Name->new($revision);
		$name->is_valid('revision') or die "Invalid revision $revision\n";
		my @n = $name->get;
		my $version_subdir = $n[2] ne ""?
			"$n[1]--$n[2]/$n[1]--$n[2]--$n[3]": "$n[1]/$n[1]--$n[3]";
		my $subdir = "{arch}/$n[1]/$version_subdir/$n[0]/patch-log/$n[4]";
		my $file = "$self->{dir}/$subdir";
		$message = load_file($file) if -f $file;
	} else {
		$message = run_tla("cat-log", "-d", $self->{dir}, $revision);
	}
	return undef unless $message;

	my $log = Arch::Log->new($message, hide_ids => $self->{hide_ids});
	$self->{cached_logs}->{$revision} = $log
		if $self->{cache_logs};
	return $log;
}

sub get_logs ($;$) {
	my $self = shift;
	my $version = shift || $self->get_version;
	my $versions = ref($version) eq 'ARRAY'? $version:
		$version eq '*'? $self->get_log_versions: [ $version ];

	my @logs = ();
	foreach (@$versions) {
		my $revisions = $self->get_log_revisions($_);
		foreach my $revision (@$revisions) {
			push @logs, $self->get_log($revision);
		}
	}
	return wantarray? @logs: \@logs;
}

sub get_log_revision_descs ($;$) {
	my $self = shift;
	my $version = shift;

	my $logs = $self->get_logs($version);
	my $revision_descs = [];
	foreach my $log (@$logs) {
		push @$revision_descs, $log->get_revision_desc;
	}
	return $revision_descs;
}

sub get_inventory ($) {
	my $self = shift;

	return Arch::Inventory->new($self->root);
}

# TODO: properly support file name escaping
sub get_changes ($) {
	my $self = shift;
	my $is_baz = is_baz();
	my @args = $is_baz ? qw(status) : qw(changes -d);
	my @lines = run_tla(@args, $self->{dir});

	return undef
		if ($? >> 8) == 2;

	my $baz_1_1_conversion_table;
	$baz_1_1_conversion_table = {
		'A ' => [ 'A ', 'A/' ],
		'D ' => [ 'D ', 'D/' ],
		'R ' => [ '=>', '/>' ],
		' M' => [ 'M ', '??' ],
		' P' => [ '--', '-/' ],
	} if $is_baz;

	my $changes = Arch::Changes->new;
	foreach my $line (@lines) {
		next if $line =~ /^\*/;
		next if $line eq "";

		# work around baz-1.1 tree-lint messages
		last if $line =~ /^These files would be source but lack inventory ids/;

		# support baz
		if ($is_baz && $line =~ /^([ADR ][ MP])  (.+?)(?: => (.+))?$/) {
			my $tla_prefix = $baz_1_1_conversion_table->{$1};
			die "Unknown 'baz status' line: $line\n" unless $tla_prefix;
			# baz-1.1 lacks info about dirs, so stat file (may not work)
			my $is_dir = $1 eq 'R '
				? -d "$self->{dir}/$3"
				: -d "$self->{dir}/$2";
			$line = $tla_prefix->[$is_dir ? 1 : 0] . " $2";
			$line .= "\t$3" if $3;
		}

		$line =~ m!^([ADM=/-])([ />b-]) ([^\t]+)(?:\t([^\t]+))?$!
			or die("Unrecognized changes line: $line\n");

		my $type   = $1;
		my $is_dir = ($1 eq '/') || ($2 eq '/');
		my @args   = ($3, $4);

		# fix tla changes inconsistency with renamed directories ('/>' vs '=/')
		$type = '=' if $type eq '/';

		$changes->add($type, $is_dir, @args);
	}

	return $changes;
}

sub get_changeset ($$) {
	my $self = shift;
	my $dir  = shift;

	die("Directory already exists: $dir\n")
		if (-d $dir);

	my $cmd = is_baz()? "diff": "changes";
	run_tla($cmd, "-d", $self->{dir}, "-o", $dir);

	return -f "$dir/mod-dirs-index"
		? Arch::Changeset->new("changes.".$self->get_version(), $dir)
		: undef;
}

sub get_merged_log_text ($) {
	my $self = shift;
	my $text = run_tla("log-for-merge", "-d", $self->{dir});
	return $text;
}

sub get_merged_revision_summaries ($) {
	my $self = shift;
	my $text = $self->get_merged_log_text;
	my @hash = ();

	$text eq "" or $text =~ s/^Patches applied:\n\n//
		or die "Unexpected merged log output:\n$text\n";

	while ($text =~ s/^ \* (.*)\n(.+\n)*\n//) {
		push @hash, $1;
		my $summary = $2;
		$summary =~ s/^   //g;
		$summary =~ s/\n$//;
		push @hash, $summary;
	}
	die "Unexpected merged log sub-output:\n$text\n" if $text ne "";

	return @hash if wantarray;
	my %hash = @hash;
	return \%hash;
}

sub get_merged_revisions ($) {
	my $self = shift;

	my $revision_summaries = $self->get_merged_revision_summaries;
	my @array = sort keys %$revision_summaries;
	return wantarray ? @array : \@array;
}

sub get_missing_revisions ($;$) {
	my $self = shift;
	my $version = shift || $self->get_version;

	$self->{missing_revisions}->{$version} ||= [
		run_tla("missing", "-d", $self->{dir}, $version)
	];
	my $array = $self->{missing_revisions}->{$version};
	return wantarray ? @$array : $array;
}

sub get_missing_revision_descs ($;$) {
	my $self = shift;
	my $version = shift || $self->get_version;

	unless ($self->{missing_revision_descs}->{$version}) {
		my @revision_lines =
			map { /^\S/? (undef, $_): $_ }
			run_tla("missing -scD", "-d", $self->{dir}, $version);
		shift @revision_lines;  # throw away first undef

		my $revision_descs = _parse_revision_descs(4, \@revision_lines);
		$self->{missing_revision_descs}->{$version} = $revision_descs;
		$self->{missing_revisions}->{$version} =
			[ map { $_->{name} } @$revision_descs ];
	}
	return $self->{missing_revision_descs}->{$version};
}

# for compatibility only, may be removed after summer 2005
*get_missing_revision_details = *get_missing_revision_descs;
*get_missing_revision_details = *get_missing_revision_details;

sub get_previous_revision ($;$) {
	my $self = shift;
	my $revision = shift || $self->get_revision;

	return adjacent_revision($revision, -1)
		unless $revision =~ /^(.*)--version-0$/;

	# handle version-0 case specially, can't be guessed from the name alone
	my $revisions = $self->get_log_revisions($1);
	until (pop @$revisions eq $revision) {
	}
	return $revisions->[-1];
}

sub get_ancestry_logs ($%) {
	my $self = shift;
	my %args = @_;

	my $limit = $args{limit} || 0;
	my $callback = $args{callback};
	my $one_version = $args{one_version} || 0;
	my $no_continuation = $args{no_continuation} || 0;

	my @collected = ();
	my $version = $self->get_version if $one_version;
	my $revision = $self->get_revision;
	while ($revision) {
		my $log = $self->get_log($revision);

		# handle removed logs
		unless ($log) {
			$revision = $self->get_previous_revision($revision);
			next;
		}

		my $kind = $log->get_revision_kind;
		if ($kind eq 'import') {
			$revision = undef;
		} elsif ($kind eq 'tag') {
			$revision = $no_continuation
				? undef
				: $log->continuation_of;
			$revision &&= undef
				if $one_version && $revision !~ /^\Q$version--/;
		} else {
			$revision = $self->get_previous_revision($revision);
		}
		push @collected, $callback? $callback->($log): $log;
		last unless --$limit && $log;  # undefined by callback
	}
	return \@collected;
}

# for compatibility only, may be removed after summer 2005
sub iterate_ancestry_logs ($;$$) {
	my $self = shift;
	my $cb = shift;
	my $nc = shift || 0;
	return $self->get_ancestry_logs(callback => $cb, no_continuation => $nc);
}

sub get_history_revision_descs ($;$%) {
	my $self = shift;
	my $filepath = shift;
	@_ = (one_version => $_[0]) if @_ == 1;  # be compatible until summer 2005
	my %args = @_;

	my $limit = delete $args{limit} || 0;
	my $callback = delete $args{callback};

	my ($is_dir, $changed);
	if (defined $filepath) {
		my $full_filepath = "$self->{dir}/$filepath";
		# currently stat the existing tree file/dir
		$is_dir = -l $full_filepath? 0: -d _? 1: -f _? 0:
			die "No tree file or dir ($full_filepath)\n";
		$filepath =~ s!/{2,}!/!g;
		$filepath =~ s!^/|/$!!g;
		$filepath = "." if $filepath eq "";  # avoid invalid input die
	}

	return $self->get_ancestry_logs(%args, callback => sub {
		my $log = $_[0];
		if (defined $filepath) {
			$changed = $log->get_changes->is_changed("to", $filepath, $is_dir);
			return unless defined $changed;
		}
		my $revision_desc = $log->get_revision_desc;

		if (defined $filepath) {
			$revision_desc->{filepath} = $filepath;
			$revision_desc->{is_filepath_added}    = $changed->{&ADD}?    1: 0;
			$revision_desc->{is_filepath_renamed}  = $changed->{&RENAME}? 1: 0;
			$revision_desc->{is_filepath_modified} = $changed->{&MODIFY}? 1: 0;

			$revision_desc->{orig_filepath} = $filepath = $changed->{&RENAME}
				if $revision_desc->{is_filepath_renamed};
			$_[0] = undef
				if $revision_desc->{is_filepath_added};
		}

		my @returned = $callback
			? $callback->($revision_desc, $log)
			: $revision_desc;

		$_[0] = undef unless --$limit && $revision_desc;  # undefined by callback
		return @returned;
	});
}

# for compatibility only, may be removed after 2005
*get_ancestry_revision_descs = *get_history_revision_descs;
*get_ancestry_revision_descs = *get_ancestry_revision_descs;

# parse input like "3-5,8" or [ 3..5, 8 ] or { 3 => 1, 4 => 1, 5 => 1, 8 => 1 }
sub _get_skip_hash_from_linenums ($$) {
	my $linenums = shift;
	my $max_linenum = shift;

	my %skip_linenums = ();
	if (defined $linenums) {
		%skip_linenums = map { $_ => 1 } 1 .. $max_linenum;
		if (!ref($linenums)) {
			$linenums = [ map {
				die "Invalid line range ($_)\n" unless /^(\d+)?(-|\.\.)?(\d+)?$/;
				$2? ($1 || 1) .. ($3 || $max_linenum): $1
			} split(',', $linenums) ];
		}
		if (ref($linenums) eq 'ARRAY') {
			$linenums = { map { $_ => 1 } @$linenums };
		}
		if (ref($linenums) eq 'HASH') {
			delete $skip_linenums{$_} foreach keys %$linenums;
		}
	}
	return \%skip_linenums;
}

sub _eq ($$) {
	my $value1 = shift;
	my $value2 = shift;
	return defined $value1 && defined $value2 && $value1 == $value2
		|| !defined $value1 && !defined $value2;
}

# see tests/tree-annotate-1 to understand input and output
sub _group_annotated_lines ($$) {
	my $lines = shift;
	my $line_rd_indexes = shift;

	my $last_line_index = undef;
	my $last_rd_index = -1;
	for (my $i = @$lines; @$lines && $i >= 0; $i--) {
		if ($i == 0 || !_eq($last_rd_index, -1) && !_eq($line_rd_indexes->[$i - 1], $last_rd_index)) {
			splice(@$line_rd_indexes, $i + 1, $last_line_index - $i);
			splice(@$lines, $i, $last_line_index - $i + 1, [ @$lines[$i .. $last_line_index] ]);
		}
		if ($i > 0 && (_eq($last_rd_index, -1) || !_eq($line_rd_indexes->[$i - 1], $last_rd_index))) {
			$last_line_index = $i - 1;
			$last_rd_index = $line_rd_indexes->[$i - 1];
		}
	}
}

sub get_annotate_revision_descs ($$;%) {
	my $self = shift;
	my $filepath = shift || die "No file to annotate\n";
	my %args = @_;

	my $prefetch_callback = delete $args{prefetch_callback};
	my $callback = delete $args{callback};
	my $linenums = delete $args{linenums};
	my $match_re = delete $args{match_re};
	my $highlight = delete $args{highlight};
	my $full_history = delete $args{full_history};
	$linenums ||= [] if $match_re;  # no lines by default if regexp given

	my $full_filepath = "$self->{dir}/$filepath";
	die "No file $full_filepath to annotate\n" unless -f $full_filepath;

	require Arch::DiffParser;
	my $diff_parser = Arch::DiffParser->new;
	my @lines;
	load_file($full_filepath, \@lines);

	if ($highlight) {
		require Arch::FileHighlighter;
		my $fh = Arch::FileHighlighter->instance;
		my $html_ref = $fh->highlight($full_filepath);
		chomp($$html_ref);
		@lines = split(/\n/, $$html_ref, -1);
	}

	my @line_rd_indexes = (undef) x @lines;
	my @line_rd_index_refs = map { \$_ } @line_rd_indexes;

	my $num_unannotated_lines = @lines;
	my $num_revision_descs = 0;
	my $session = Arch::Session->instance;

	# limit to certain lines only if requested, like "12-24,50-75,100-"
	my $skip_linenums = _get_skip_hash_from_linenums($linenums, 0 + @lines);
	if ($match_re) {
		my $re = eval { qr/$match_re/ };
		die "get_annotate_revision_descs: invalid regexp /$match_re/: $@" unless defined $re;
		$lines[$_ - 1] =~ $re && delete $skip_linenums->{$_} for 1 .. @lines;
	}
	$num_unannotated_lines -= keys %$skip_linenums;
	$line_rd_index_refs[$_ - 1] = undef foreach keys %$skip_linenums;

	my $revision_descs = $num_unannotated_lines == 0? []:
	$self->get_history_revision_descs($filepath, %args, callback => sub {
		my ($revision_desc, $log) = @_;

		goto FINISH if $num_unannotated_lines == 0;
		my $old_num_unannotated_lines = $num_unannotated_lines;

		# there is no diff on import, so include all lines manually
		if ($log->get_revision_kind eq 'import') {
			for (my $i = 1; $i <= @line_rd_index_refs; $i++) {
				my $ref = $line_rd_index_refs[$i - 1];
				if ($ref && !$$ref) {
					$$ref = $num_revision_descs;
					$num_unannotated_lines--;
				}
			}
			goto FINISH;
		}

		# only interested in file addition and modification
		goto FINISH unless $revision_desc->{is_filepath_modified}
			|| $revision_desc->{is_filepath_added};

		# fetch changeset first
		my $revision = Arch::Name->new($revision_desc->{version})
			->apply($revision_desc->{name});
		my $filepath = $revision_desc->{filepath};
		$prefetch_callback->($revision, $filepath) if $prefetch_callback;
		my $changeset = eval {
			$session->get_revision_changeset($revision);
		};
		# stop if some ancestry archive is not registered or accessible
		unless ($changeset) {
			$_[0] = undef;
			return ();
		}
		# get file diff if any
		my $diff = $changeset->get_patch($filepath);
		# ignore metadata modification
		goto FINISH if $diff =~ /^\*/;

		# calculate annotate data for file lines affected in diff
		my $changes = $diff_parser->parse($diff)->changes;
		foreach my $change (reverse @$changes) {
			my ($ln1, $size1, $ln2, $size2) = @$change;
			for (my $i = $ln2; $i < $ln2 + $size2; $i++) {
				die "get_annotate_revision_descs: inconsistent source line #$i in diff:\n"
					. "    $revision\n    $filepath\n"
					. "    ($ln1, $size1, $ln2, $size2)\n"
					if $i > @line_rd_index_refs;
				my $ref = $line_rd_index_refs[$i - 1];
				if ($ref && !$$ref) {
					$$ref = $num_revision_descs;
					$num_unannotated_lines--;
				}
			}
			splice(@line_rd_index_refs, $ln2 - 1, $size2, (undef) x $size1);
		}

		FINISH:
		die "get_annotate_revision_descs: inconsistency (some lines left)\n"
			if $revision_desc->{is_filepath_added} && $num_unannotated_lines > 0;
		die "get_annotate_revision_descs: inconsistency (got extra lines)\n"
			if $num_unannotated_lines < 0;

		# stop "history" processing if all lines are annotated
		$_[0] = undef
			if !$full_history && $num_unannotated_lines == 0;

		# skip "history" revision that does not belong to "annotate"
		return () if !$full_history
			&& $old_num_unannotated_lines == $num_unannotated_lines;

		$num_revision_descs++;

		my @returned = $callback
			? $callback->($revision_desc, $log)
			: $revision_desc;

		$_[0] = undef unless $revision_desc;  # undefined by callback
		return @returned;
	});

	return $revision_descs unless wantarray;

	_group_annotated_lines(\@lines, \@line_rd_indexes) if $args{group};
	return (\@lines, \@line_rd_indexes, $revision_descs);
}

sub clear_cache ($;@) {
	my $self = shift;
	my @keys = @_;

	@keys = qw(missing_revision_descs missing_revisions cached_logs)
		unless @keys;

	foreach (@keys) {
		if (@_ && !exist $self->{$_}) {
			warn __PACKAGE__ . "::clear_cache: unknown key ($_), ignoring\n";
			next;
		}
		$self->{$_} = {};
	}

	return $self;
}

sub get_file_diff ($$) {
	my $self = shift;
	my $path = shift;

	my $cwd = getcwd;
	chdir($self->{dir});
	my $cmd = has_file_diffs_cmd()? "file-diffs": "file-diff";
	my $diff = run_tla($cmd, "-N", $path);
	chdir($cwd);

	return $diff;
}

sub add ($;@) {
	my $self = shift;
	my $opts = shift if ref($_[0]) eq 'HASH';
	my @files = @_;

	my @args = ();
	push @args, "--id", $opts->{id} if $opts->{id};
	push @args, @files;

	my $cwd = getcwd();
	chdir($self->{dir}) && run_tla("add-id", @args);
	chdir($cwd);

	return $?;
}

sub delete ($;@) {
	my $self = shift;
	my @files = @_;

	my $cwd = getcwd();
	chdir($self->{dir}) && run_tla("delete-id", @files);
	chdir($cwd);

	return $?;
}

sub move ($;@) {
	my $self = shift;
	my @files = @_;

	my $cwd = getcwd();
	chdir($self->{dir}) && run_tla("move-id", @files);
	chdir($cwd);

	return $?;
}

sub make_log ($) {
	my $self = shift;

	my ($file) = run_tla("make-log", "-d", $self->{dir});
	return $file;
}

sub import ($;$@) {
	my $self = shift;
	return unless ref($self);  # ignore perl's import() method
	my $opts = shift if ref($_[0]) eq 'HASH';
	my $version = shift || $self->get_version;

	my $is_baz = is_baz();
	my @args = ();
	foreach my $opt (qw(archive log summary log-message)) {
		push @args, "--$opt", $opts->{$opt} if $opts->{$opt};
	}
	push @args, "--setup" unless $is_baz || $opts->{nosetup};
	push @args, "--dir" unless $is_baz;
	push @args, $opts->{dir} || $self->{dir};

	# baz-1.2 advertizes but does not actually support directory argument
	# this block may be deleted later (the bug is fixed in baz-1.3)
	if ($is_baz) {
		my $cwd = getcwd();
		my $dir = pop @args;
		chdir($dir) && run_tla("import", @args, $version);
		chdir($cwd);
		return $?;
	}

	run_tla("import", @args, $version);

	return $?;
}

sub commit ($;$) {
	my $self = shift;
	my $opts = shift if ref($_[0]) eq 'HASH';
	my $version = shift;

	my @args = ();
	push @args, "--dir", $self->{dir} unless $opts->{dir};
	foreach my $opt (qw(archive dir log summary log-message file-list)) {
		my $_opt = $opt; $_opt =~ s/-/_/g;
		push @args, "--$opt", $opts->{$_opt} if $opts->{$_opt};
	}
	foreach my $opt (qw(strict seal fix out-of-date-ok)) {
		my $_opt = $opt; $_opt =~ s/-/_/g;
		push @args, "--$opt" if $opts->{$_opt};
	}

	if (has_commit_version_arg()) {
		push @args, $version || $self->get_version;
	} elsif ($version) {
		warn "This arch backend's commit does not support version arg\n";
	}

	my $files = $opts->{files};
	if ($files) {
		die "commit: files is not ARRAY ($files)\n"
			unless ref($files) eq 'ARRAY';
		push @args, "--" if has_commit_files_separator();
		push @args, @$files;
	}

	run_tla("commit", @args);

	return $?;
}

1;

__END__

=head1 NAME

Arch::Tree - class representing Arch tree

=head1 SYNOPSIS

    use Arch::Tree;
    my $tree = Arch::Tree->new;  # assume the current dir

    print map { "$_\n" } $tree->get_log_versions;

    foreach my $log ($tree->get_logs) {
        print "-" x 80, "\n";
        print $log->standard_date, "\n";
        print $log->summary, "\n\n";
        print $log->body;
    }

=head1 DESCRIPTION

This class represents the working tree concept in Arch and provides some
useful methods.

=head1 METHODS

The following methods are available:

B<new>,
B<root>,
B<get_version>,
B<set_version>,
B<get_log_versions>,
B<add_log_version>,
B<get_log_revisions>,
B<get_log>,
B<get_logs>,
B<get_log_revision_descs>,
B<get_inventory>,
B<get_changes>,
B<get_changeset>,
B<get_merged_log_text>,
B<get_merged_revision_summaries>,
B<get_merged_revisions>,
B<get_missing_revisions>,
B<get_missing_revision_descs>,
B<get_previous_revision>,
B<get_ancestry_logs>,
B<get_history_revision_descs>,
B<get_annotate_revision_descs>,
B<clear_cache>,
B<add>,
B<delete>,
B<mode>,
B<get_file_diff>,
B<make_log>,
B<import>,
B<commit>.

=over 4

=item B<new> [I<dir-name>]

Construct the Arch::Tree object associated with the existing directory
I<dir-name>. The default is the current '.' directory.

=item B<root>

Returns the project tree root.

=item B<get_version>

Returns the fully qualified tree version.

=item B<get_revision>

Returns the fully qualified tree revision.

=item B<set_version> I<version>

Changes the tree version to I<version>.

=item B<get_log_versions>

Returns all version names (including the main one and merged ones) for which
logs are stored in the tree. In the scalar context returns arrayref.

=item B<add_log_version> I<version>

Add log version I<version> to project tree.

=item B<get_log_revisions> [I<version>]

Returns all revision names of the given I<version> (the default is the tree
version) for which logs are stored in the tree. In the scalar context
returns arrayref.

=item B<get_log> I<revision>

Return Arch::Log object corresponding to the tree log of the given I<revision>.

=item B<get_logs> [I<version>]

Return Arch::Log objects corresponding to the tree logs of the given I<version>.
In the scalar context returns arrayref.

The default I<version> is the tree version (see C<get_version>).
A special version name '*' may be used, in this case all logs in
C<get_log_versions> are returned. I<version> may be arrayref as well
with the similar results.

=item B<get_log_revision_descs> [I<version>]

Returns arrayref of log revision description hashes corresponding to
I<version>. The optional I<version> argument may get the same values that
are supported by B<get_logs>.

=item B<get_inventory>

Returns L<Arch::Inventory> object for the project tree.

=item B<get_changes>

Returns a list of uncommited changes in the project tree.

=item B<get_changeset> I<dir>

Creates an B<Arch::Changeset> of the uncommited changes in the
tree. The directory I<dir> is used to store the changeset and must not
already exist. It will not be automatically removed.

=item B<get_merged_log_text>

This is just the output of "tla log-for-merge".

=item B<get_merged_revision_summaries>

Returns hash (actually sorted array of pairs) or hashref in the scalar
context. The pair is for every merged revision: full-name => summary.

=item B<get_merged_revisions>

The list of all merged in (present in the changes) full revisions.
In the scalar context returns arrayref.

=item B<get_missing_revisions> [I<version>]

The list of all missing revisions corresponding to I<version>.
In the scalar context returns arrayref.

The default I<version> is the tree version (see C<get_version>).

=item B<get_missing_revision_descs> [I<version>]

The hashref of all missing revision descriptions corresponding to I<version>.
The hash keys are revisions and the values are hashrefs with keys
I<name>, I<summary>, I<creator>, I<email>, I<date>, I<kind>.

The default I<version> is the tree version (see C<get_version>).

=item B<get_previous_revision> [<revision>]

Given the fully qualified revision name (defaulting to B<get_revision>)
return the previous namespace revision in this tree version. Return undef
for the I<base-0> revision. Note, the I<version-0> revision argument is
handled specially.

=item B<get_ancestry_logs> [I<%args>]

Return all ancestry revision logs (calculated from the tree). The first log
in the returned arrayref corresponds to the current tree revision, the last
log is normally the original import log. If the tree has certain logs pruned
(such practice is not recommended), then such pruned log is not returned and
this method tries its best to determine its ancestor, still without
accessing the archive.

I<%args> accepts: flags I<no_continuation> and I<one_version>, and
I<callback> to filter a revision log before it is collected.

If I<no_continuation> is set, then do not follow tags backward.

If I<one_version> is set, then do not follow tags from the versions
different than the initial version. This is similar to I<no_continuation>,
but not the same, since it is possible to tag into the same version.

The default callback is effectivelly:

    sub {
        my ($log) = @_;
        return $log;
    }

Note that if the callback does $_[0] = undef among other things, this is
taken as a signal to stop processing of ancestry (the return value is still
collected even in this case; return empty list to collect nothing).

=item B<get_history_revision_descs> [I<filepath> [I<%args>]]

Return arrayref of all ancestry revision descriptions in the backward order
(i.e. from a more recent to an older). If I<filepath> is given, then only
revisions that modified the given file (or dir) are returned. The revision
description is hashref with keys I<name>, I<summary>, I<creator>, I<email>,
I<date>, I<kind>.

If I<filepath> if given, then the revision description hash additionally
contains keys I<filepath>, I<orig_filepath> (if renamed on that revision),
I<is_filepath_added>, I<is_filepath_renamed> and I<is_filepath_modified>.

I<%args> accepts: flags I<no_continuation> and I<one_version>, and
I<callback> to filter a revision description before it is collected.

The default callback is effectivelly:

    sub {
        my ($revision_desc, $log) = @_;
        return $revision_desc;
    }

The I<%args> flags and assigning to $_[0] in callback have the same meaning
as in B<get_ancestry_logs>.

=item B<get_annotate_revision_descs> [I<filepath> [I<%args>]]

Return file annotation data. In scalar context, returns arrayref of all
ancestry revision descriptions in the backward order (i.e. from a more
recent to an older) responsible for last modification of all file lines.
In list context, returns list of 3 values:

    ($lines, $line_revision_desc_indexes, $revision_descs) =
        $tree->get_annotate_revision_descs($filename);

$lines is arrayref that contains all I<filepath> lines with no end-of-line;
$line_revision_desc_indexes is arrayref of the same length that contains
indexes to the $revision_descs arrayref. Note that $revision_descs is the
same returned in the scalar context, it is similar to the one returned by
B<get_history_revision_descs>, but possibly contains less elements, since
some revisions only modified metadata, or only modified lines that were
modified by other revisions afterward, all such revisions are not included.

If some lines can't be annotated (usually, because the history was cut),
then the corresonding $line_revision_desc_indexes elements are undefined.

I<%args> accepts: flags I<no_continuation> and I<one_version>, and
I<callback> to filter a revision description before it is collected.

The default callback is effectivelly:

    sub {
        my ($revision_desc, $log) = @_;
        return $revision_desc;
    }

The I<%args> flags and assigning to $_[0] in callback have the same meaning
as in B<get_ancestry_logs> and B<get_history_revision_descs>.

Additionally, I<prefetch_callback> is supported. If given, it is called
before fetching a changeset, with two arguments: revision, and filename to
look at the patch of which.

More I<%args> keys are I<linenums> (either string or arrayref or
hashref), I<match_re> (regular expression to filter lines). And flags
I<highlight> (syntax highlight lines using markup), I<full_history>
(include all file history revision even those that didn't add the current
file lines).

=item B<clear_cache> [key ..]

For performance reasons, some method results are cached (memoized in fact).
Use this method to explicitly request this cache to be cleared.

By default all cached keys are cleared; I<key> may be one of the strings
'missing_revision_descs', 'missing_revisions'.

=item B<add> [{ I<options> }] I<files ...>

Add exlicit inventory ids for I<files>. A specific inventory id may be
passed via the I<options> hash with the key C<id>.

=item B<delete> I<files ...>

Delete explicit inventory ids for I<files>.

=item B<move> I<old_file> I<new_file>

Move exlicit file id for I<old_file> to I<new_file>.

=item B<get_file_diff> I<file>

Get modifications for I<file> as unified diff.

=item B<make_log>

Create a new commit log, if it does not yet exist. Returns the
filename.

=item B<import> [{ I<options> }] [I<version>]

Similar to 'tla import'.

=item B<commit> [{ I<options> }] [I<version>]

Commit changes in tree.

Note, I<version> argument is not supported in newer baz versions.

Optional file limits may be passed using I<files> arrayref in I<options>.

=back

=head1 BUGS

Awaiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<tla>, L<Arch::Log>, L<Arch::Inventory>,
L<Arch::Changes>, L<Arch::Util>, L<Arch::Name>.

=cut
