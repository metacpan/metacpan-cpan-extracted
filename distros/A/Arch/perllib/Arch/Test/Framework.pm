# Arch Perl library, Copyright (C) 2005 Enno Cramer
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

package Arch::Test::Framework;

use Arch::Test::Archive;
use Arch::Test::Tree;
use Arch::Test::Cases;

use Arch::TempFiles qw();
use Arch::Util qw();

sub new ($;%) {
	my $class = shift;
	my %args = @_;

	my $home = $args{home} || Arch::TempFiles::temp_dir('arch-test');

	my $self = {
		arch_uid => '',
		home     => $home,
		library  => $args{library}  || "$home/library",
		archives => $args{archives} || "$home/archives",
		trees    => $args{trees}    || "$home/trees",
		ids      => {},
	};

	die "Cannot access directory $self->{home}\n"
		unless -d $home && -w $home;

	bless $self, $class;

	# setup home directory
	foreach my $dir ((
		$self->archives_dir,
		$self->library_dir,
		$self->trees_dir
	)) {
		mkdir $dir unless -d $dir;
	}

	unless (-d "$self->{home}/.arch-params") {
		$self->run_tla(
			'my-id',
			$args{userid} || 'Arch Perl Test <arch-perl-test@example.com>'
		);

		$self->run_tla(
			'my-revision-library',
			$self->library_dir
		);

		$self->run_tla(
			'library-config',
			'--sparse', '--non-greedy',
			$self->library_dir
		);
	}

	$self->{arch_uid} = $self->run_tla('my-id', '--uid');

	return $self;
}

# field access
sub arch_uid ($) {
	my $self = shift;

	return $self->{arch_uid};
}

sub home_dir ($) {
	my $self = shift;

	return $self->{home};
}

sub library_dir ($) {
	my $self = shift;

	return $self->{library};
}

sub archives_dir ($) {
	my $self = shift;

	return $self->{archives};
}

sub trees_dir ($) {
	my $self = shift;

	return $self->{trees};
}

# run with correct environment
sub run_tla ($@) {
	my $self = shift;

	local $ENV{HOME} = $self->home_dir;
	my @lines = Arch::Util::run_tla(@_);

	die "run_tla(".join(' ', @_).") failed: $?\n"
		if $?;

	return wantarray ? @lines : $lines[0];
}

sub gen_id ($$) {
	my $self = shift;
	my $section = shift;

	$self->{ids}->{$section} = 0
		unless exists $self->{ids}->{$section};

	return $self->{ids}->{$section}++;
}

sub make_archive ($;$) {
	my $self = shift;
	my $name = shift
		|| $self->arch_uid . '--archive-' . $self->gen_id('archives');

	my $path = $self->archives_dir . "/$name";
	$self->run_tla('make-archive', $name, $path);

	return Arch::Test::Archive->new($self, $name);
}

sub make_tree ($$;$) {
	my $self = shift;
	my $version = shift;
	my $tree = shift || 'tree-' . $self->gen_id('trees');

	my $path = $self->trees_dir . "/$tree";
	mkdir($path) || die "mkdir($path) failed: $!\n";
	$self->run_tla('init-tree', '-d', $path, $version);

	return Arch::Test::Tree->new($self, $path);
}

1;

__END__

=head1 NAME

Arch::Test::Framework - A test framework for Arch-Perl

=head1 SYNOPSIS 

    use Arch::Test::Framework;

    my $fw = Arch::Test::Framework->new;

    my $archive = $fw->make_archive;
    my $version = $archive->make_version();

    my $tree = $fw->make_tree($version);

    #
    # do something with $tree
    #

    $tree->import('initial import');


=head1 DESCRIPTION

Arch::Test::Framework is a framework to quickly generate testing data
(archives, versions, trees, changesets, etc) for arch-perl unit tests.

=head1 METHODS

B<new>,
B<arch_uid>,
B<home_dir>,
B<library_dir>,
B<archives_dir>,
B<trees_dir>,
B<make_archive>,
B<make_category>,
B<make_branch>,
B<make_version>,
B<make_tree>.

=over 4

=item B<new> [I<%args>]

Create a new arch-perl test environment.

Valid keys for I<%args> are I<home> to specify an existing test
environment to reuse, I<library> to specify a different revision
library path, I<archives> to specify a different archives directory,
and I<trees> to specify a differente project tree directory. The
default values are C<$home/library>, C<$home/archives>, and
C<$home/trees> respectively.

A different arch user id can be selected with the I<userid> key, the
default is C<Arch Perl Test E<lt>arch-perl-test@example.comE<gt>>.

=item B<arch_uid>

=item B<home_dir>

=item B<library_dir>

=item B<archives_dir>

=item B<trees_dir>

These methods return the environment parameters as initialized by B<new>.

=item B<make_archive> [I<archive_name>]

Create a new archive in the archives directory. If I<archive_name> is
not specified a unique name is generated. The archive name is
returned. Returns an L<Arch::Test::Archive> reference for the archive.

=item B<make_tree> I<version> [I<name>]

Create and initialize (C<tla init-tree>) a new project tree for
I<version>. I I<name> is not specified, a unique identifier will be
generated. Returns an L<Arch::Test::Tree> reference for the project
tree.

=back

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=cut
