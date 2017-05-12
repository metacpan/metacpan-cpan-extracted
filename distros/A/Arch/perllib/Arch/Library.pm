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

package Arch::Library;

use base 'Arch::Storage';

use Arch::Util qw(run_tla load_file standardize_date parse_creator_email date2age);
use Arch::Changeset;
use Arch::Log;
use Arch::Backend qw(has_revlib_patch_set_dir);
use Arch::TempFiles qw(temp_dir);

sub _default_fields ($) {
	my $this = shift;
	return (
		$this->SUPER::_default_fields,
		fallback_dir => undef,
		ready_to_add => 0,
		path => undef,
		working_revision => undef,
		revision_trees => {},
	);
}

sub archives ($) {
	my $self = shift;
	return [ run_tla('library-archives') ];
}

sub categories ($;$) {
	my $self = shift;
	my $archive = shift || $self->working_name;
	return [ run_tla('library-categories', $archive) ];
}

sub branches ($;$) {
	my $self = shift;
	my $full_category = shift || $self->working_name;
	return [ run_tla('library-branches', $full_category) ];
}

sub versions ($;$) {
	my $self = shift;
	my $full_branch = shift || $self->working_name;
	return [ run_tla('library-versions', $full_branch) ];
}

sub revisions ($;$) {
	my $self = shift;
	my $full_version = shift || $self->working_name;
	return [ run_tla('library-revisions', $full_version) ];
}

sub get_revision_descs ($;$) {
	my $self = shift;
	my $full_version = shift || $self->working_name;
	my @lines = run_tla('library-revisions -Dcs', $full_version);

	my @revision_descs = ();
	while (@lines) {
		my ($name, $date, $creator) = splice @lines, 0, 3;
		die "Unexpected date line ($date) in tla library-revisions -Dcs\n"
			unless $date =~ s/^    //;
		die "Unexpected creator line ($creator) in tla library-revisions -Dcs\n"
			unless $creator =~ s/^    //;

		my @summary_lines = ();
		push @summary_lines, shift @lines while @lines && $lines[0] =~ /^    |^\t/;
		my $summary = join("\n", @summary_lines);
		$summary =~ s/^    |^\t//mg;

		$date = standardize_date($date);
		my $age = date2age($date);
		my ($creator1, $email, $username) = parse_creator_email($creator);

		push @revision_descs, {
			name     => $name,
			summary  => $summary,
			creator  => $creator1,
			email    => $email,
			username => $username,
			date     => $date,
			age      => $age,
			kind     => 'lib',
		};
	}
	return \@revision_descs;
}

*revision_details = *get_revision_descs; *revision_details = *revision_details;

sub expanded_archive_info ($;$$) {
	my $self = shift;

	my $old_working_name = $self->working_name;
	my $archive_name = shift || $old_working_name;
	$self->working_name($archive_name);
	my ($archive, $category0, $branch0) = $self->working_names;
	my $full_listing = shift || 0;

	my $infos = [];
	$self->working_names($archive);
	foreach my $category ($category0? ($category0): @{$self->categories}) {
		$self->working_names($archive, $category);
		push @$infos, [ $category, [] ];
		foreach my $branch ($branch0? ("$category--$branch0"): @{$self->branches}) {
			$branch = "" unless $branch =~ s/^\Q$category\E--//;
			$self->working_names($archive, $category, $branch);
			push @{$infos->[-1]->[1]}, [ $branch, [] ];
			foreach my $version (@{$self->versions}) {
				die unless $version =~ s/^\Q$category\E(?:--)?\Q$branch\E--//;
				$self->working_names($archive, $category, $branch, $version);
				my $revisions = $self->revisions;
				my $revisions2 = [];
				if ($full_listing) {
					$revisions2 = $revisions;
				} else {
					my $revision0 = $revisions->[0] || '';
					my $revisionl = $revisions->[-1] || '';
					$revisionl = '' if $revision0 eq $revisionl;
					push @$revisions2, $revision0, $revisionl;
				}
				push @{$infos->[-1]->[1]->[-1]->[1]}, [ $version, @$revisions2 ];
			}
		}
	}

	$self->working_name($old_working_name);
	return $infos;
}

sub fallback_dir ($;$) {
	my $self = shift;
	if (@_) {
		my $dir = shift;
		$self->{fallback_dir} = $dir;
	}
	return $self->{fallback_dir};
}

sub working_revision ($;$) {
	my $self = shift;
	if (@_) {
		my $revision = shift;
		$self->{working_revision} = $revision;
	}
	return $self->{working_revision};
}

sub add_revision ($$) {
	my $self = shift;
	my $revision = shift;
	unless ($self->{ready_to_add}) {
		($self->{path}) = run_tla("my-revision-library --silent --add");
		my $fallback_dir = $self->{fallback_dir};
		if (!$self->{path} && $fallback_dir) {
			# don't create more than one directory level to avoid typos
			mkdir($fallback_dir, 0777) unless -d $fallback_dir;
			run_tla("my-revision-library $fallback_dir");
			($self->{path}) = run_tla("my-revision-library --silent --add");
		}
		$self->{ready_to_add} = 1 if $self->{path};
	}
	die "Can't attempt to add revision. No revision-library is defined?\n"
		unless $self->{ready_to_add};
	run_tla("library-add --sparse $revision");
	my $dir = $self->find_revision_tree($revision);
	die "Adding revision $revision to library failed.\nBad permissions or corrupt archive?\n"
		unless $dir;
	return $dir;
}

sub find_revision_tree ($$;$) {
	my $self = shift;
	my $revision = shift || die "find_revision_tree: No revision given\n";
	my $auto_add = shift || 0;
	return $self->{revision_trees}->{$revision} if $self->{revision_tree};
	my ($dir) = run_tla("library-find -s $revision");
	if (!$dir && $auto_add) {
		$dir = $self->add_revision($revision);
	}
	return $self->{revision_trees}->{$revision} = $dir;
}

sub find_tree ($;$) {
	my $self = shift;
	$self->find_revision_tree($self->{working_revision}, @_);
}

sub get_revision_changeset ($$) {
	my $self = shift;
	my $revision = shift || die "get_revision_changeset: No revision given\n";

	my $dir;
	if (has_revlib_patch_set_dir()) {
		my $tree_root = $self->find_revision_tree($revision);
		die "No revision $revision found in library\n" unless $tree_root;

		$dir = "$tree_root/,,patch-set";
	} else {
		$dir = temp_dir();
		run_tla('get-changeset', $revision, $dir);
	}

	return Arch::Changeset->new($revision, $dir);
}

sub get_changeset ($) {
	my $self = shift;
	$self->get_revision_changeset($self->{working_revision}, @_);
}

sub get_revision_log ($$) {
	my $self = shift;
	my $revision = shift || die "get_revision_log: No revision given\n";

	my $message;
	if (has_revlib_patch_set_dir()) {
		my $tree_root = $self->find_revision_tree($revision);
		die "No revision $revision found in library\n" unless $tree_root;

		my $log_file = "$tree_root/,,patch-set/=log.txt";
		die "Missing log $log_file in revision library\n" unless -f $log_file;
		$message = load_file($log_file);
	} else {
		$message = run_tla('library-log', $revision);
	}

	return Arch::Log->new($message);
}

sub get_log ($) {
	my $self = shift;
	$self->get_revision_log($self->{working_revision}, @_);
}

1;

__END__

=head1 NAME

Arch::Library - access arch revision libraries

=head1 SYNOPSIS

    use Arch::Library;

    my $library = Arch::Library->new;

    my $rev  = 'migo@homemail.com--Perl-GPL/arch-perl--devel--0--patch-1';
    my $log  = $library->get_revision_log($rev);
    my $cset = $library->get_revision_changeset($rev);

=head1 DESCRIPTION

Arch::Library provides an interface to access pristine trees,
changesets and logs stored in local revision libraries.

=head1 METHODS

The following common methods (inherited and pure virtual that
this class implements) are documented in L<Arch::Storage>:

B<new>,
B<init>,
B<working_name>,
B<working_names>,
B<fixup_name_alias>,
B<is_archive_managed>,
B<expanded_revisions>.

B<archives>,
B<categories>,
B<branches>,
B<versions>,
B<revisions>,
B<get_revision_descs>,
B<expanded_archive_info>,
B<get_revision_changeset>,
B<get_changeset>,
B<get_revision_log>,
B<get_log>.

Additionally, the following methods are available:

B<fallback_dir>,
B<working_revision>,
B<add_revision>,
B<find_revision_tree>,
B<find_tree>.

=over 4

=item B<fallback_dir> [I<dir>]

Get or set the fallback directory. Defaults to C<undef>.

If no revision library exists, the fallback directory will be used as
revision library when adding revisions with B<add_revision>.

=item B<working_revision> [I<revision>]

Get or set the default revision for B<find_tree>, B<get_changeset> and
B<get_log>.

=item B<find_revision_tree> I<revision> [I<autoadd>]

=item B<find_tree> [I<autoadd>]

Returns the path to the revision library structure for revision
I<revision> or B<working_revision>.

Returns an empty string if I<revision> is not in the revision library
and I<autoadd> is not set. If I<autoadd> is set, I<revision> will be
added to the revision library.

=back

=head1 BUGS

No known bugs.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<tla>, L<Arch::Storage>, L<Arch::Library>.

=cut
