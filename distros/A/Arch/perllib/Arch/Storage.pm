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

package Arch::Storage;

use Arch::Name;

sub new ($%) {
	my $class = shift;
	my %init = @_;

	my $self = { $class->_default_fields };
	bless $self, $class;
	$self->init(%init);

	no strict 'refs';
	${"${class}::global_instance"} = $self;
	return $self;
}

sub instance ($) {
	my $class = shift;

	no strict 'refs';
	return ${"${class}::global_instance"} || $class->new;
}

sub init ($%) {
	my $self = shift;
	my %init = @_;
	while (my ($name, $value) = each %init) {
		die ref($self) . "::init: Option $name is unknown.\n"
			unless exists $self->{$name};
		$self->{$name} = $value;
	}
	return $self;
}

sub _default_fields ($) {
	my $this = shift;
	return (
		name => Arch::Name->new,
	);
}

sub working_name ($;$) {
	my $self = shift;
	if (@_) {
		$self->{name} = Arch::Name->new(shift);
		$self->fixup_name_alias;
	}
	return $self->{name};
}

sub working_names ($;$@) {
	my $self = shift;
	if (@_) {
		$self->{name} = Arch::Name->new(ref($_[0])? $_[0]: [ @_ ]);
	}
	return $self->{name}->get;
}

sub fixup_name_alias ($) {
	my $self = shift;
	$self->{name_alias} = 0;
	$self->{version_alias} = undef;
	$self->{revision_alias} = undef;

	my $name = $self->{name};
	my ($version, $revision) = ($name->get)[3, 4];
	foreach (
		[ qw(version versions branch), $version ],
		[ qw(revision revisions version), $revision ]
	) {
		my ($element, $method, $parent, $alias) = @$_;
		if (defined $alias && $alias =~ /^FIRST|LATEST$/) {
			$name->$element(undef);
			my $values = $self->$method($name);
			die "There is no any $element in this $parent, so $name--$alias alias is invalid\n"
				unless @$values;
			my $value = $values->[$alias eq "FIRST"? 0: -1];
			$value =~ s/^.*--//;
			$name->$element($value);
			$name->revision($revision) unless $element eq 'revision';
			$self->{name_alias} = 1;
			$self->{"${element}_alias"} = $alias;
		}
	}
}

sub _name_operand ($$;$) {
	my $self = shift;
	my $arg  = shift;
	my $elem = shift;
	my $func = (caller(1))[3];

	my $name = $arg? Arch::Name->new($arg): $self->{name};
	die "$func: no working name and no argument given\n" unless $name;
	if ($elem) {
		my $enclosing = $name->cast($elem);
		die "$func: operand '$name' is not $elem\n" unless $enclosing;
		$name = $enclosing;
	}
	return $name;
}

sub is_archive_managed ($;$) {
	my $self = shift;
	my $archive = $self->_name_operand(shift, 'archive');

	unless ($self->{archives_presence}) {
		my $archives_hash = {};
		$archives_hash->{$_} = 1 foreach @{$self->archives};
		$self->{archives_presence} = $archives_hash;
	}
	return $self->{archives_presence}->{$archive};
}

sub expanded_revisions ($) {
	my $self = shift;

	my $all_revisions = [];
	my $archives = $self->archives;
	foreach my $archive (@$archives) {
		my $category_infos = $self->expanded_archive_info($archive, 1);
		foreach my $category_info (@$category_infos) {
			my ($category, $branch_infos) = @$category_info;
			foreach my $branch_info (@$branch_infos) {
				my ($branch, $version_infos) = @$branch_info;
				foreach my $version_info (@$version_infos) {
					my ($version, @revisions) = @$version_info;
					foreach my $revision (@revisions) {
						my $name = Arch::Name->new([
							$archive, $category, $branch, $version, $revision,
						]);
						die $name->error .
							"\n\t($archive, $category, $branch, $version, $revision)\n"
							if $name->error;
						push @$all_revisions, $name;
					}
				}
			}
		}
	}

	return $all_revisions;
}

1;

__END__

=head1 NAME

Arch::Storage - abstract class to access arch archives

=head1 SYNOPSIS

    use base 'Arch::Storage';

    # see synopsis of concrete classes

=head1 DESCRIPTION

Arch::Storage provides some common methods to query content of arch archive.

The methods usually return arrayref if not otherwise specified, and
are not affected by the list context (except for working_names).

=head1 METHODS

The following (implemented and pure virtual) methods are common to subclasses:

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

=over 4

=item B<new> [I<%args>]

Create a new instance of the concrete subclass (i.e. L<Arch::Session> or
L<Arch::Library>).

=item B<instance>

Alternative constructor. Return the last created instance of the concrete
subclass (i.e. L<Arch::Session> or L<Arch::Library>) or create a new one.

The purpose of this alternative constructor is to allow the singleton
behaviour as well as certain Aspect Oriented Programming practices.

Theoretical note: this design is acceptably good, and mixing B<new> and
B<instance> constructors in the code usually does what is intended. However,
if someone actually creates more than one object of any subclass, he has two
choices to enforce correctness. Either only use B<instance> method in the
code (singleton pattern), or alternatively create a temporary B<new> object
before calling methods of other classes that internally use B<instance> to
work with this subclass.

=item B<init> I<%args>

Initialize or reset the object state.

=item B<working_name> [I<name>]

Set or get the default working operand for other methods.

The argument may be anything that L<Arch::Name> constructor accepts,
i.e. fully qualified string, arrayref, hashref or Arch::Name instance.
If needed, I<name> is converted to L<Arch::Name> instance, and this is
what is returned. Note that this object behaves as fully qualified name
in string context.

=item B<working_names> [I<archive> ..]

Similar to B<working_name>, but accepts and returns a list of name
components, from I<archive> to I<revision>.

This method is provided for convenience and backward compatibility only.
You may as well use B<working_name> instead, just enclose the argument list
into arrayref, and call B<to_array> on the returned object.

=item B<fixup_name_alias>

Replace (if needed) the "FIRST" and "LATEST" components of the working name's
I<version> and I<revision> with the actual values by querying the storage.

=item B<is_archive_managed> [I<archive>]

Return true or false depending on whether the archive is known to the
storage.

If given, the argument is used instead of the default B<working_name>.

=item B<expanded_revisions>

Return all revisions in all archives, each revision is Arch::Name object.

=item B<archives>

Return all registered (or otherwise known) archives.

=item B<categories> [I<archive>]

=item B<branches>   [I<category>]

=item B<versions>   [I<branch>]

=item B<revisions>  [I<version>]

Return all categories, branches, versions or revisions respectively
in the immediate parent, similarly to the corresponding I<tla> commands.

If given, the argument is used instead of the default B<working_name>.

=item B<get_revision_descs> [I<version>]

Return describing hash for every revision in the version.

If given, the argument is used instead of the default B<working_name>.

The revision hashes have the following fields:

=over 4

=item B<name>

The revision name (i.e. C<base-0>, C<patch-X>, C<version-0> or C<versionfix-X>)

=item B<summary>

The revision's commit log's summary line

=item B<creator>

The name part of the committers C<tla my-id> (i.e. C<John Hacker>)

=item B<email>

The email address part of the committers C<tla my-id>
(i.e. C<jhacker@nowhere.org>)

=item B<date>

The revisions commit date in C<%Y-%m-%d %H:%M:%S %Z> format (see
L<strftime(3)>)

=item B<kind>

The kind of revision (i.e. one of C<tag>, C<import>, C<cset> or C<unknown>)

=back

=item B<expanded_archive_info> [I<archive>]

Returns a tree of categories, branches and versions in the
archive. The archive defaults to B<working_names>.

Returns a reference to a list of categories. Every category is a list
consisting of the category name and a list of branches. Every branch
is a list consisting of the branch name and a list of versions. Every
version is list consisting of the version number and the first and
last revision name.

    [
      [ "category1", [
        [ "branch1", [
          [ "version1", "first_revision1", "last_revision1" ],
          [ "version2", "first_revision2", "last_revision2" ],
          ...
        ],
        ...
      ],
      ...
    ]

=item B<get_revision_changeset> I<revision> [I<dir>]

=item B<get_changeset> [I<dir>]

Fetches the changeset for I<revision> or B<working_name> and returns
an L<Arch::Changeset> for it. If I<dir> is specified, it will be used to
store the contents of the changeset. Otherwise a new temporary
directory will be created.

=item B<get_revision_log> I<revision>

=item B<get_log>

Fetch the log for the I<revision> or B<working_name>. Returns an
L<Arch::Log> object.

=back

=head1 BUGS

No known bugs.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<tla>, L<Arch::Session>, L<Arch::Library>.

=cut
