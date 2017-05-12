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

package Arch::Test::Archive;

use Arch::Backend qw(has_archive_setup_cmd);

sub new ($$$) {
	my $class = shift;
	my ($fw, $name) = @_;

	my $self = {
		name      => $name,
		framework => $fw,
		structure => {
		}
	};

	bless $self, $class;

	return $self;
}

sub name ($) {
	my $self = shift;

	return $self->{name};
}

sub framework ($) {
	my $self = shift;

	return $self->{framework};
}

sub run_tla ($@) {
	my $self = shift;

	$self->framework->run_tla(@_);
}

# name generation
sub gen_id ($;@) {
	my $self = shift;
	my @tree = @_;

	die "gen_id is private"
		if caller ne __PACKAGE__;

	my $ref = $self->{structure};
	foreach my $key (@tree) {
		$ref->{$key} = { '=count' => 0 }
			unless exists $ref->{$key};

		$ref = $ref->{$key};
	}

	return $ref->{'=count'}++;
}

sub split_arch_name ($$$) {
	my $self = shift;
	my $name = shift || '';
	my $maxlen = shift || 3;

	if ($name =~ s,^(.+)/,,) {
		die "Prefix from different archive: $1\n"
			if $1 ne $self->name;
	}
		
	my @parts = $name ? split /--/, $name : ();

	die "Arch name $name too long\n"
		if @parts > $maxlen;

	return @parts;
}

sub join_arch_name ($@) {
	my $self = shift;

	return join '--', @_;
}


sub make_category ($;$) {
	my $self = shift;
	my @prefix = @_;

	unshift @prefix, $self->split_arch_name(shift @prefix, 1);

	if (@prefix < 1) {
		push @prefix, "category-" . $self->gen_id(@prefix);
	}

	my $name = $self->join_arch_name(@prefix);
	$self->run_tla('archive-setup', '-A', $self->name, $name)
		if has_archive_setup_cmd();

	return $self->name . "/$name";
}

sub make_branch ($;$$) {
	my $self = shift;
	my @prefix = @_;

	unshift @prefix, $self->split_arch_name(shift @prefix, 2);

	if (@prefix < 2) {
		@prefix = $self->split_arch_name($self->make_category(@prefix), 1)
			if @prefix < 1;

		push @prefix, 'branch-' . $self->gen_id(@prefix);
	}

	my $name = $self->join_arch_name(@prefix);
	$self->run_tla('archive-setup', '-A', $self->name, $name)
		if has_archive_setup_cmd();

	return $self->name . "/$name";
}

sub make_version ($;$$$) {
	my $self = shift;
	my @prefix = @_;

	unshift @prefix, $self->split_arch_name(shift @prefix, 3);

	if (@prefix < 3) {
		@prefix = $self->split_arch_name($self->make_branch(@prefix), 2)
			if @prefix < 2;

		push @prefix, $self->gen_id(@prefix);
	}

	my $name = $self->join_arch_name(@prefix);
	$self->run_tla('archive-setup', '-A', $self->name, $name)
		if has_archive_setup_cmd();

	return $self->name . "/$name";
}


1;

__END__

=head1 NAME

Arch::Test::Archive - A test framework for Arch-Perl

=head1 SYNOPSIS 

    use Arch::Test::Framework;

    my $fw = Arch::Test::Framework->new;
    my $archive = $fw->make_archive;

    my $version1 = $archive->make_version();
    my $version2 = $archive->make_version($branch);


=head1 DESCRIPTION

Arch::Test::Archive provides methods to quickly build and modify Arch
archives.

=head1 METHODS

B<new>,
B<name>,
B<framework>,
B<run_tla>
B<make_category>,
B<make_branch>,
B<make_version>,

=over 4

=item B<new> I<framework> I<name>

Create a new Arch::Test::Archive instance for archive I<name>. This
method should not be called directly.

=item B<name>

Returns the archive name.

=item B<framework>

Returns the associated Arch::Test::Framework reference.

=item B<run_tla> I<@args>

Run tla with the specified arguments.

=item B<make_category> [I<category>]

=item B<make_branch>   [I<category> [I<branch>]]

=item B<make_version>  [I<category> [I<branch> [I<version>]]]

Create a new category, branch or version. A unique name for
unspecified parts is generated. The fully qualified name is returned.

=back

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=cut
