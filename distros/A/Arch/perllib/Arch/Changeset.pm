# Arch Perl library, Copyright (C) 2004 Mikhael Goikhman
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

package Arch::Changeset;

use Arch::Util qw(load_file adjacent_revision);
use Arch::Changes qw(:type);

sub new ($$$) {
	my $class = shift;
	my $revision = shift || die "Arch::Changeset::new: no revision\n";
	my $dir = shift || die "Arch::Changeset::new: no dir\n";
	die "No changeset dir $dir for revision $revision\n" unless -d $dir;

	$dir =~ s!/$!!;

	my $self = {
		revision   => $revision,
		dir        => $dir,
		ancestor   => undef,
		index_memo => {},
	};

	return bless $self, $class;
}

sub get_patch ($$;$$) {
	my $self = shift;
	my $filepath = shift;
	my $type = shift || 0;
	# 0 - unknown, 1 - modified (including metadata), 2 - new, 3 - removed
	$type = { MODIFY => 1, ADD => 2, DELETE => 3 }->{$type} || 0
		unless $type =~ /^[0123]$/;
	my $full_file_asis = shift || 0;
	my $dir = $self->{dir};
	my $change_type = "";

	my $patch_file = "$dir/patches/$filepath.patch";
	if (!-f $patch_file && $type == 0 || $type == 2) {
		$patch_file = "$dir/new-files-archive/$filepath";
		$change_type = "new";
	}
	if (!-f $patch_file && $type == 0 || $type == 3) {
		$patch_file = "$dir/removed-files-archive/$filepath";
		$change_type = "removed";
	}

	if (!-f $patch_file) {
		my $patch_content = "*** Currently unsupported patch type, possibly metadata or symlink change ***";
		if ($type >= 2) {
			if (-l $patch_file) {
				$patch_content = readlink($patch_file);
			} else {
				die "No file $filepath patch in revision $self->{revision} changeset\n";
			}
		} else {
			$patch_file = "/dev/null";
			$change_type = "unsupported";
		}
		return wantarray? ($patch_content, $patch_file, $change_type, 1): $patch_content;
	}
	my $patch_content = load_file($patch_file);

	# create fake patch from full file if needed
	my $asis = 0;
	if ($change_type ne "" && !($asis = $full_file_asis || -B $patch_file)) {
		my $has_end_line = $patch_content =~ /\n$/;
		my $num_lines = $patch_content =~ s/\n/\n/g;
		$num_lines += $has_end_line? 0: 1;
		my $file = $patch_file;
		$file =~ s!^\Q$dir\E/[^/]+/!!s;
		my ($file1, $file2, $line1, $line2, $prefix);
		if ($change_type eq "new") {
			$file1 = "/dev/null";
			$file2 = $file;
			$line1 = "-0,0";
			$line2 = "+1,$num_lines";
			$prefix = "+";
		} else {
			$file1 = $file;
			$file2 = "/dev/null";
			$line1 = "-1,$num_lines";
			$line2 = "+0,0";
			$prefix = "-";
		}
		chop $patch_content if $has_end_line;
		$patch_content =~ s/(^|\012)/$1$prefix/g;
		$patch_content .= "\n\\ No newline at end of file" unless $has_end_line;
		$patch_content = "--- $file1\n+++ $file2\n@@ $line1 $line2 @@\n$patch_content\n";
		$change_type = "";
	}

	$change_type ||= "patch";
	return wantarray? ($patch_content, $patch_file, $change_type, $asis): $patch_content;
}

sub ancestor ($) {
	my $self = shift;
	my $ancestor = $self->{ancestor};
	return $ancestor if $ancestor;

	if (-f "$self->{dir}/=ancestor") {
		$ancestor = load_file("$self->{dir}/=ancestor");
		chomp($ancestor);
	}
	unless ($ancestor) {
		# just guess
		my $revision = $self->{revision};
		$ancestor = adjacent_revision($revision, -1) || $revision;
	}
	return $self->{ancestor} = $ancestor;
}

sub get_index ($$) {
	my $self  = shift;
	my $index = shift;

	return %{$self->{index_memo}->{$index}}
		if (exists $self->{index_memo}->{$index});

	my $index_hash = {};

	# TODO: add proper unescaping support
	foreach my $line (split /\n/, load_file($self->{dir} . '/' . $index)) {
		my ($path, $id) = split / /, $line, 2;

		$path =~ s,^\./,,;
		$index_hash->{$id} = $path;
	}

	$self->{index_memo}->{$index} = $index_hash;
	return %$index_hash;
}

sub get_changes ($) {
	my $self = shift;

	my %orig_dirs  = $self->get_index('orig-dirs-index');
	my %mod_dirs   = $self->get_index('mod-dirs-index');

	my %orig_files = $self->get_index('orig-files-index');
	my %mod_files  = $self->get_index('mod-files-index');

	my $changes = Arch::Changes->new;

	# added dirs
	foreach my $id (keys %mod_dirs) {
		$changes->add(ADD, 1, $mod_dirs{$id})
			unless (exists $orig_dirs{$id});
	}

	# added files
	foreach my $id (keys %mod_files) {
		$changes->add(ADD, 0, $mod_files{$id})
			unless (exists $orig_files{$id});
	}

	# deleted dirs
	foreach my $id (keys %orig_dirs) {
		$changes->add(DELETE, 1, $orig_dirs{$id})
			unless (exists $mod_dirs{$id});
	}

	# deleted files
	foreach my $id (keys %orig_files) {
		$changes->add(DELETE, 0, $orig_files{$id})
			unless (exists $mod_files{$id});
	}

	# modified files
	foreach my $id (keys %mod_files) {
		$changes->add(MODIFY, 0, $mod_files{$id})
			if (-f $self->{dir} . '/patches/' . $mod_files{$id} . '.patch');
	}

	# dir metadata changes
	foreach my $id (keys %mod_dirs) {
		$changes->add(META_MODIFY, 1, $mod_dirs{$id})
			if (-f $self->{dir} . '/patches/' . $mod_dirs{$id} . '/=dir-meta-mod');
	}

	# file metadata changes
	foreach my $id (keys %mod_files) {
		$changes->add(META_MODIFY, 0, $mod_files{$id})
			if (-f $self->{dir} . '/patches/' . $mod_files{$id} . '.meta-mod');
	}

	my %ren_dirs;
	foreach (keys %orig_dirs) {
		$ren_dirs{$orig_dirs{$_}} = $mod_dirs{$_}
			if exists $mod_dirs{$_};
	}

	# moved dirs
	foreach my $id (keys %orig_dirs) {
		if (
			exists $orig_dirs{$id} &&
			exists $mod_dirs{$id} &&
			$orig_dirs{$id} ne $mod_dirs{$id}
		) {
			(my $parent = $orig_dirs{$id}) =~ s!/?[^/]+$!!;
			my $tail = $&;
			my $found  = 0;

			while (!$found && $parent) {
				$found = exists $ren_dirs{$parent}
					&& (($ren_dirs{$parent} . $tail) eq $mod_dirs{$id});

				$parent =~ s!/?[^/]+$!!;
				$tail = $& . $tail;
			}

			$changes->add(RENAME, 1, $orig_dirs{$id}, $mod_dirs{$id})
				if !$found;
		}
	}

	# moved files
	foreach my $id (keys %orig_files) {
		if (
			exists $orig_files{$id} &&
			exists $mod_files{$id} &&
			$orig_files{$id} ne $mod_files{$id}
		) {
			(my $parent = $orig_files{$id}) =~ s!/?[^/]+$!!;
			my $tail = $&;
			my $found  = 0;

			while (!$found && $parent) {
				last if $tail =~ m!^/\.arch-ids/!;

				$found = exists $ren_dirs{$parent}
					&& (($ren_dirs{$parent} . $tail) eq $mod_files{$id});

				$parent =~ s!/?[^/]+$!!;
				$tail = $& . $tail;
			}

			$changes->add(RENAME, 0, $orig_files{$id}, $mod_files{$id})
				if !$found;
		}
	}

	return $changes;
}

sub get_all_diffs ($;%) {
	my $self = shift;
	my %params = @_;

	my @diffs = ();
	my $changes = $self->get_changes;
	foreach my $change ($changes->get) {
		next if $change->{is_dir};
		my $type = $change->{type};
		next unless $type eq MODIFY
			|| !$params{no_new_files} && ($type eq ADD || $type eq DELETE);
		my $filepath = $change->{arguments}->[0];
		next if $params{no_arch_files} &&
			($filepath =~ m!^{arch}/! || $filepath =~ m!(^|/).arch-ids/!);
		push @diffs, scalar $self->get_patch($filepath, $type)
			|| "*** $filepath ***\n*** binary content not displayed ***";
	}

	return wantarray? @diffs: \@diffs;
}

sub join_all_diffs ($;%) {
	my $self = shift;

	my $diffs = $self->get_all_diffs(@_);

	return join('', map { "\n$_\n" } @$diffs);
}

1;

__END__

=head1 NAME

Arch::Changeset - class representing Arch changeset

=head1 SYNOPSIS

B<Arch::Changeset> objects may be created directly if you got a changeset
directory:

    use Arch::Changeset;
    my $changeset = Arch::Changeset->new(
        'migo@homemail.com--Perl-GPL/arch-perl--devel--0--patch-6',
        '/tmp/,,changeset-6',
    );

But often are created indirectly by other objects:

    use Arch::Session;
    $changeset = Arch::Session->new->get_revision_changeset(
        'migo@homemail.com--Perl-GPL/arch-perl--devel--0--patch-6'
    );

    use Arch::Library;
    $changeset = Arch::Library->new->get_revision_changeset(
        'migo@homemail.com--Perl-GPL/arch-perl--devel--0--patch-6'
    );

    print scalar $changeset->get_patch("perllib/Arch/Changeset.pm");

    my $diff_file = ($changeset->get_patch("README", 1))[2];
    print Arch::Util::load_file($diff_file);

=head1 DESCRIPTION

This class represents the changeset concept in Arch and provides some
useful methods.

=head1 METHODS

The following methods are available:

B<new>,
B<get_patch>,
B<get_index>,
B<get_changes>,
B<get_all_diffs>,
B<join_all_diffs>,
B<ancestor>.

=over 4

=item B<new> I<revision-spec> I<dir-name>

Construct the Arch::Changeset object associated with the given
fully-qualified I<revision-spec> and the existing directory I<dir-name>.

=item B<get_patch> I<file-path>

=item B<get_patch> I<file-path> I<type>

=item B<get_patch> I<file-path> I<type> I<full-file-asis>

Return the patch (or otherwise content) of the given I<file-path> in the
changeset.

I<type> is integer: 0 (unknown, try to autodetect, this is the default),
1 (modified file, or metadata change), 2 (new file), 3 (removed file).

The default behaviour is to create a fake diff against I</dev/null> for
non-binary new and removed files; the I<full-file-asis> flag, if set to
true, changes this behaviour and causes to return the content of such file
as-is. Binary new and removed files are always returned as-is regardless
of the flag. This flag is also ignored if I<type> is 1.

In the scalar content return the patch in diff(1) format (or the whole file
content as described above). In the list content return 4 scalars: the
patch, the file name on the disk containing this patch (or the whole file),
the change type (that is "patch", "new" or "removed") and the as-is flag.

The returned values that follow the first one (the patch/file content)
share the order of the corresponding parameters; the parameters are
more hints, while the returned values accurately describe the content.

=item B<get_index> I<name>

Returns the content of the index file I<name> as an B<ID> => B<path> hash.

Valid I<name>s are 'orig-dirs-index', 'orig-files-index', 'mod-dirs-index' and
'mod-files-index'.

=item B<get_changes>

Returns a list of changes in the changeset.

=item B<get_all_diffs>

Returns all diffs in the changeset (array or arrayref). This includes
changes of types I<MODIFY>, I<ADD> and I<DELETE>.

=item B<join_all_diffs>

Returns concatenated output of all diffs in the changeset.

=item B<ancestor>

Return the ancestor of the changeset. If I<=ancestor> file is found (that is
the case for library changesets) its content is returned, otherwise try to
guess the ancestor of the revision using B<Arch::Util::adjacent_revision>.

=back

=head1 BUGS

Awaiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<tla>, L<Arch::Session>, L<Arch::Library>,
L<Arch::Util>.

=cut
