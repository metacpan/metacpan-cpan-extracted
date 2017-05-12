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

package Arch::Changes;

use Exporter;
BEGIN { *Arch::Changes::import = *Exporter::import; }
use vars qw(@EXPORT_OK %EXPORT_TAGS);

@EXPORT_OK = qw(
	ADD DELETE REMOVE MODIFY META_MODIFY RENAME 
);
%EXPORT_TAGS = (
	type => [ qw(ADD DELETE REMOVE MODIFY META_MODIFY RENAME) ],
);


use Arch::Util qw(run_tla);

use constant ADD         => 'A';
use constant DELETE      => 'D';
use constant REMOVE      => 'D';  # obsolete, may be removed after summer 2005
use constant MODIFY      => 'M';
use constant META_MODIFY => '-';
use constant RENAME      => '=';

sub new ($$) {
	my $class = shift;

	my $self = {
		changes => [],
	};

	return bless $self, $class;
}

sub add ($$$@) {
	my $self = shift;
	my ($type, $is_dir, @args) = @_;

	push @{$self->{changes}}, {
		type      => $type,
		is_dir    => $is_dir ? 1 : 0,
		arguments => [ @args ],
	};
}

sub count ($) {
	my $self = shift;

	return scalar @{$self->{changes}};
}

sub get ($;$) {
	my $self = shift;
	my $num  = shift;

	return $self->{changes}->[$num]
		if defined $num;

	return @{$self->{changes}};
}

sub get_listing ($) {
	my $self = shift;

	my $ret = '';
	foreach my $change ($self->get) {
		$ret .= Arch::Changes->to_string($change);
		$ret .= "\n";
	}

	return $ret;
}

sub is_changed ($$$;$) {
	my $self = shift;
	my $to = { qw(0 0 1 1 from 0 to 1) }->{shift()};
	die "No 0/1/from/to param" unless defined $to;
	my $filepath = shift || die "No file/dir name";
	my $is_dir = shift;

	my $changed = {};
	foreach my $change (reverse $self->get) {
		my $dst_filepath = $change->{arguments}->[$to - 1];
		my $src_filepath = $change->{arguments}->[0 - $to];

		# support larch "features"
		$dst_filepath =~ s!^\./!!;
		$src_filepath =~ s!^\./!!;

		# flag the file change if matching
		if ($src_filepath eq $filepath
			&& (!defined $is_dir || $change->{is_dir} == $is_dir)
		) {
			$changed->{$change->{type}} =
				$change->{type} ne RENAME? 1: $dst_filepath;
		}

		# handle renames of parent directories (the most close change)
		if ($change->{type} eq RENAME && $change->{is_dir}
			&& $filepath =~ m!^\Q$src_filepath\E(/.+)$!
			&& !exists $changed->{RENAME()}
		) {
			$changed->{$change->{type}} = "$dst_filepath$1";
		}
	}
	$changed = undef unless %$changed;

	return $changed;
}

sub dump ($) {
	my $self = shift;

	require Data::Dumper;
	my $dumper = Data::Dumper->new([$self->get]);
	$dumper->Sortkeys(1) if $dumper->can('Sortkeys');
	$dumper->Quotekeys(0);
	$dumper->Indent(1);
	$dumper->Terse(1);

	return $dumper->Dump;
}

my %TYPE_EXT = (
	ADD()         => ' ',
	DELETE()      => ' ',
	MODIFY()      => ' ',
	META_MODIFY() => '-',
	RENAME()      => '>',
);

sub type_string ($$) {
	my $class = shift;
	my $change = shift;

	if ($change->{is_dir}) {
		return $change->{type} eq RENAME
			? '/>'
			: $change->{type} . '/';
	} else {
		return $change->{type} . $TYPE_EXT{$change->{type}};
	}
}

sub to_string ($$) {
	my $class = shift;
	my $change = shift;

	return sprintf("%s %s",
		Arch::Changes->type_string($change),
		join("\t", @{$change->{arguments}}),
	);
}

1;

__END__

=head1 NAME

Arch::Changes - class representing a list of changes

=head1 SYNOPSIS

    use Arch::Changes qw(:type);

    use Arch::Tree;
    my $changes = $tree->get_changes;
    print $changes->get_listing;

    use Arch::Log;
    my $changed = $log->get_changes->is_changed('to', "COPYING");
    die "License was compromised" if $changed && $changed->{&MODIFY};

=head1 DESCRIPTION

Arch::Changes contains a list of elements, each representing a single
tree change. Each change element is described by a hash with the
following fields:

=over 4

=item B<type>

The type of the change. Can be one of B<ADD>, B<DELETE>, B<MODIFY>,
B<META_MODIFY> or B<RENAME>.

=item B<is_dir>

A boolean value indicating whether the affected tree element is a
directory.

=item B<arguments>

A list of arguments. The first element is always relative path of the
affected tree element. For changes of type B<RENAME> the first
argument is the old path and the second argument the new path name.

=back

The type constants can be conveniently imported using the tag C<:type>.

    use Arch::Changes qw(:type);

=head1 METHODS

The following methods are available:

B<new>,
B<add>,
B<count>,
B<get>,
B<get_listing>,
B<is_changed>,
B<dump>,
B<type_string>,
B<to_string>.

=over 4

=item B<new>

Creates a new, initially empty, changes list.

Typically it is called indirectly from method B<get_changes> in
L<Arch::Changeset>, L<Arch::Tree> or L<Arch::Log> class.

=item B<add> I<type> I<is_dir> I<arguments...>

Adds a new change element to the list of changes.

Typically it is called indirectly from method B<get_changes> in
L<Arch::Changeset>, L<Arch::Tree> or L<Arch::Log> class.

=item B<count>

Returns the number of change elements.

=item B<get> I<num>

Returns the I<num>-th change element or all if I<num> is undefined.

=item B<get_listing>

Generates a textual changes listing as produced by C<tla changes>.

=item B<is_changed> I<to> I<filepath> [I<is_dir>]

Verify whether the given I<filepath> is modified by the changes. The I<to>
parameter may get boolean values "0", "1", "from" or "to", it only affects
B<RENAME> changes, and in some sense B<ADD> and B<DELETE> changes. If I<to>
is set, then the given I<filepath> is taken as the destination of B<RENAME>
or B<ADD>, otherwise as the source of B<RENAME> or B<DELETE>. The B<MODIFY>
and B<META_MODIFY> changes are not affected, since the destination and the
source is the same file/dir.

If I<filepath> is not modified by any changes, return undef.

Otherwise, return hash with possible keys B<ADD>, B<DELETE>, B<MODIFY>,
B<META_MODIFY> and B<RENAME>. The hash values are 1 in all cases except for
B<RENAME>, then the value is the file name on the opposite side (i.e.,
the source of B<RENAME> if I<to> is true, and the destination if false).

Note, the valid return values for arch are: undef, hashref with one key
(B<ADD> or B<DELETE>) or hashref with combination of one-to-three
keys (B<MODIFY>, B<META_MODIFY> and B<RENAME>).

=item B<dump>

Generates a dump of the changes list using Data::Dumper.

=item B<type_string> I<change>

Returns the change type string as produced by C<tla changes>.

=item B<to_string> I<change>

Generates a changes line for I<change> as produced by C<tla changes>.

=back

=head1 BUGS

Awaiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<tla>, L<Arch::Changeset>, L<Arch::Tree>,
L<Arch::Log>.

=cut
