# Arch Perl library, Copyright (C) 2004 Mikhael Goikhman, Enno Cramer
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

package Arch::Inventory;

use Exporter;
BEGIN { *Arch::Inventory::import = *Exporter::import; }
use vars qw(@EXPORT_OK %EXPORT_TAGS);

@EXPORT_OK = qw(
	TREE SOURCE PRECIOUS BACKUP JUNK UNRECOGNIZED
	FILE DIRECTORY SYMLINK
	TAGLINE EXPLICIT NAME
);
%EXPORT_TAGS = (
	category => [ qw(TREE SOURCE PRECIOUS BACKUP JUNK UNRECOGNIZED) ],
	type     => [ qw(FILE DIRECTORY SYMLINK) ],
	id_type  => [ qw(TAGLINE EXPLICIT NAME) ],
);


use Arch::Util qw(run_tla);

use constant TREE         => 'T';
use constant SOURCE       => 'S';
use constant PRECIOUS     => 'P';
use constant BACKUP       => 'B';
use constant JUNK         => 'J';
use constant UNRECOGNIZED => 'U';

use constant FILE         => 'r';
use constant DIRECTORY    => 'd';
use constant SYMLINK      => '>';

use constant TAGLINE      => 'i';
use constant EXPLICIT     => 'x';
use constant NAMES        => '?';
use constant ARCH_CONTROL => 'A';
use constant ARCH_ID_DIR  => 'D';
use constant ARCH_ID_FILE => 'E';

sub new ($$) {
	my $class = shift;
	my $dir   = shift || ".";

	$dir =~ s!/$!!;

	die(__PACKAGE__ . ": directory $dir does not exist\n") unless -d $dir;

	my $prefix = $dir . '/';
	my $plen   = length($prefix);

	# parse inventory output
	my @inv_temp    = run_tla(qw{inventory -spbju -B --kind --ids}, $dir);
	my @inv_entries = ();
	foreach my $line (@inv_temp) {
		$line =~ /^([TSPBJU])([? ]) ([rd>]) ([^\t]+)\t(.+)$/
			or die "Unrecognized inventory line: $line\n";

		my $path = (length($4) > $plen) && (substr($4, 0, $plen) eq $prefix) ? substr($4, $plen) : $4;

		push @inv_entries, {
			category => $1,
			untagged => $2 eq '?',
			type     => $3,
			path     => $path,
			id       => $5 eq '???' ? undef : $5,
			id_type  => $5 eq '???' ? undef : substr($5, 0, 1),
		};
	}

	my $root = {
		category => -d "$dir/{arch}" ? TREE : SOURCE,
		untagged => 0,
		type     => DIRECTORY,
		path     => '',
		id       => undef,
		id_type  => undef,
		children => _build_inv_tree(0, @inv_entries),
	};

	my $self = {
		directory => $dir,
		root      => $root,
	};

	return bless $self, $class;
}

sub directory ($) {
	my $self = shift;

	return $self->{directory};
}

sub get_root_entry ($) {
	my $self = shift;

	return $self->{root};
}

sub get_entry ($@) {
	my $self = shift;
	my @path = @_;

	@path = split /\//, $path[0]
		if @path == 1;

	my $entry = $self->get_root_entry;
	while (@path && defined $entry && ($entry->{type} eq DIRECTORY)) {
		$entry = $entry->{children}->{shift @path};
	}

	return @path ? undef : $entry;
}

sub get_listing ($) {
	my $self = shift;

	my $str;
	$self->foreach(sub {
		return unless $_[0]->{path};

		$str .= Arch::Inventory->to_string($_[0]);
		$str .= "\n";
	});

	return $str;
}

sub annotate_fs ($;$) {
	my $self = shift;

	if (@_) {
		$_[0]->{stat} = [ lstat("$self->{directory}/$_[0]->{path}") ];
		$_[0]->{symlink} = readlink("$self->{directory}/$_[0]->{path}")
			if $_[0]->{type} eq SYMLINK;
	} else {
		$self->foreach(sub { $self->annotate_fs($_[0]) });
	}
}

*annotate_stat = *annotate_fs; *annotate_fs = *annotate_fs;

sub foreach ($$) {
	my $self = shift;
	my $sub  = shift;
	my $root = shift || $self->get_root_entry;

	$sub->($root);

	if ($root->{type} eq DIRECTORY) {
		foreach my $child (sort keys %{$root->{children}}) {
			$self->foreach($sub, $root->{children}->{$child});
		}
	}
}

sub dump ($) {
	my $self = shift;

	require Data::Dumper;
	my $dumper = Data::Dumper->new([$self->get_root_entry]);
	$dumper->Sortkeys(1) if $dumper->can('Sortkeys');
	$dumper->Quotekeys(0);
	$dumper->Indent(1);
	$dumper->Terse(1);

	return $dumper->Dump;
}

sub to_string ($$) {
	my $class = shift;
	my $entry = shift;

	return sprintf("%s%s %s %s\t%s",
		$entry->{category},
		$entry->{untagged} ? '?' : ' ',
		$entry->{type},
		$entry->{path},
		$entry->{id} ? $entry->{id} : '???',
	);
}

# this assumes depth first ordering of @items
sub _build_inv_tree ($@) {
	my ($cut, @entries) = @_;

	my %toplevel = ();
	while (@entries) {
		my $child = shift @entries;
		my $name  = substr($child->{path}, $cut);

		die("invalid name $name; input not in correct order\n")
			if $name =~ m!/!;

		$toplevel{$name} = $child;
		next unless $child->{type} eq DIRECTORY;

		my $prefix = $child->{path} . '/';
		my $plen   = length($prefix);

		my @children = ();
		for (my $i = 0; $i < @entries;) {
			if ((length($entries[$i]->{path}) > $plen) &&
			    (substr($entries[$i]->{path}, 0, $plen) eq $prefix)) {
				push @children, splice @entries, $i, 1;
			} else {
				++$i;
			}
		}

		$child->{children} = &_build_inv_tree($plen, @children);
	}

	return \%toplevel;
}

1;

__END__

=head1 NAME

Arch::Inventory - class representing a tree inventory

=head1 SYNOPSIS

    use Arch::Inventory qw(:category :type);

    my $inv = Arch::Inventory->new;  # use cwd
    print Arch::Inventory->to_string($inv->get_root_entry), "\n";
    print $inv->get_listing;

or (most commonly):

    use Arch::Tree;

    my $tree = Arch::Tree->new;
    my $inv = $tree->get_inventory;
    print $inv->get_listing;

=head1 DESCRIPTION

Arch::Inventory generates a tree inventory.

An inventory is a tree structure of elements, each representing a
single directory entry of the source tree. Each inventory entry is
described by an hash with the following fields:

=over 4

=item B<category>

The classification of the tree element. B<category> can be one of
B<TREE>, B<SOURCE>, B<PRECIOUS>, B<BACKUP> or B<JUNK>.

=item B<untagged>

A boolean value indicating whether the element was first classified as
B<SOURCE> but lacked an inventory id.

=item B<type>

The tree element type. B<type> can be one of B<FILE>, B<DIRECTORY> or
B<SYMLINK>.

=item B<path>

The complete path to the tree element relative to the inventory base
directory.

=item B<id>

The elements inventory id. May be C<undef>.

=item B<children>

A hash of the elements direct children, idexed by their last path element.

This field exists for elements of type B<DIRECTORY> only.

=back

The B<category> and B<type> constants can be conveniently imported using
the tags C<:category> and C<:type>.

    use Arch::Inventory qw(:category :type);

=head1 METHODS

The following methods are available:

B<new>,
B<directory>,
B<get_root_entry>,
B<get_entry>,
B<get_listing>,
B<annotate_fs>,
B<foreach>,
B<dump>,
B<to_string>.

=over 4

=item B<new> [I<$dir>]

Create an inventory for I<$dir> or the current directory if I<$dir> is
not specified.

=item B<directory>

Returns the inventories base directory as passed to B<new>.

=item B<get_root_entry>

Returns the inventory element for the base directory.

The root entry always has the following properties:

    $root = {
        category => TREE,       # if {arch} exists, SOURCE otherwise
        untagged => 1,
        type     => DIRECTORY,
        path     => '',
        id       => undef,
        children => { ... },
    }

=item B<get_entry> I<$path>

=item B<get_entry> I<@path_elements>

Returns the inventory element for the specified path. The path may
either be given as a single string or as a list of path elements.

If the element does not exist C<undef> is returned.

Using an empty or no path is equivalent to calling B<get_root_entry>.

=item B<get_listing>

Generates a textual inventory listing equivalent to the output of

    tla inventory -tspbju -B --kind --ids --untagged

B<Note:> The output order is not equivalent to tla. Instead of strict
ASCII order of path names, a directory entry is always directly
followed by its child entries. Entries with the same parent entry are
ASCII ordered.

=item B<annotate_fs>

=item B<annotate_fs> I<$entry>

Add filesystem information to I<$entry> or every inventory entry if
none is provided. This adds the fields B<stat> and B<symlink> to the
annotated entries which contain the output of B<lstat> and B<readlink>
respectively.

=item B<foreach> I<$coderef>

Execute I<$coderef> for every inventory entry, passing the entry as $_[0].

=item B<dump>

Generates a dump of the inventory structure using L<Data::Dumper>.

=item B<to_string> I<$inventory_element>

Generates an inventory line for the inventory element as produced by tla.

=back

=head1 BUGS

Awaiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<tla>, L<Arch::Util>.

=cut
