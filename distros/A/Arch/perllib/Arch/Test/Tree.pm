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

package Arch::Test::Tree;

use Arch::TempFiles qw();
use Arch::Util qw();

use POSIX qw(getcwd);

sub new {
	my $class = shift;
	my $fw = shift;
	my $path = shift;

	my $self = {
		root      => $path,
		framework => $fw,
		files     => {
		}
	};

	bless $self, $class;

	return $self;
}

sub root ($) {
	my $self = shift;

	return $self->{root};
}

sub framework ($) {
	my $self = shift;

	return $self->{framework};
}

sub run_tla ($@) {
	my $self = shift;

	my $cwd = getcwd;
	chdir($self->root);
	my @ret = $self->framework->run_tla(@_);
	chdir($cwd);

	return wantarray ? @ret : $ret[0];
}

sub run_cmd ($@) {
	my $self = shift;

	my $cwd = getcwd;
	chdir($self->root);
	my @ret = Arch::Util::run_cmd(@_);
	chdir($cwd);

	die "run_cmd(".join(' ', @_).") failed: $?\n"
		if $?;

	return wantarray ? @ret : $ret[0];
}

sub gen_id ($$) {
	my $self = shift;
	my $parent = shift;

	$self->{files}->{$parent} = 0
		unless exists $self->{files}->{$parent};

	return $self->{files}->{$parent}++;
}

sub add_file ($;$$$) {
	my $self = shift;
	my $dir  = shift || '.';
	my $name = shift || 'file-' . $self->gen_id($dir);
	my $cont = shift || "Content for $name.\n";

	my $fname = "$dir/$name";

	my $path = $self->root . "/$fname";
	Arch::Util::save_file($path, $cont);

	$self->run_tla('add-id', $fname);

	return $fname;
}

sub add_dir ($;$$) {
	my $self = shift;
	my $dir  = shift || '.';
	my $name = shift || 'dir-' . $self->gen_id($dir);

	my $fname = "$dir/$name";

	my $path = $self->root . "/$fname";
	mkdir($path) || die "mkdir($path) failed: $!\n";

	$self->run_tla('add-id', $fname);

	return $fname;
}

sub add_link ($;$$$) {
	my $self = shift;
	my $dir  = shift || '.';
	my $name = shift || 'file-' . $self->gen_id($dir);
	my $cont = shift || "Link-target-for-$name";

	my $fname = "$dir/$name";

	$self->run_cmd('/bin/ln', '-s', $cont, $fname);
	$self->run_tla('add-id', $fname);

	return $fname;
}

sub modify_file($$;$) {
	my $self = shift;
	my $file = shift;
	my $content = shift || Arch::Util::load_file($self->root . "/$file")
		. "Has been modified.\n";

	Arch::Util::save_file($self->root . "/$file", $content);
}

sub rename_file ($$$) {
	my $self = shift;
	my ($old, $new) = @_;

	my $ret = $new;

	if (-d $self->root . "/$new") {
		(my $name = $old) =~ s,(.+/),,;
		$ret .= "/$name";
	}

	$ret = './' . $ret
		unless $ret =~ /^\.\//;

	$self->run_tla('mv', $old, $new);

	return $ret;
}

sub rename_dir ($$$) {
	my $self = shift;
	my ($old, $new) = @_;

	my $ret = $new;

	if (-d $self->root . "/$new") {
		(my $name = $old) =~ s,(.+/),,;
		$ret .= "/$name";
	}

	$ret = './' . $ret
		unless $ret =~ /^\.\//;

	$self->run_cmd('mv', $old, $new);

	return $ret;
}

sub remove_file ($$) {
	my $self = shift;
	my $file = shift;

	$self->run_tla('rm', $file);
}

sub remove_dir ($$) {
	my $self = shift;
	my $dir = shift;

	Arch::Util::remove_dir($self->root . "/$dir");
}

sub inventory ($;$) {
	my $self = shift;
	my $flags = shift || '-Bs';

	return $self->run_tla('inventory', $flags);
}

# this fails in baz-1.2 (that is broken), but not in baz-1.1 and baz-1.3
sub import ($;$$) {
	my $self = shift;
	return unless ref($self);  # this is not for "use"

	my @opts = ('-d', $self->root);

	push @opts, ('-s', shift)
		if @_;

	push @opts, ('-L', shift)
		if @_;

	$self->run_tla('import', @opts);
}

sub commit ($;$$) {
	my $self = shift;

	my @opts = ('-d', $self->root);

	push @opts, ('-s', shift)
		if @_;

	push @opts, ('-L', shift)
		if @_;

	$self->run_tla('commit', @opts);
}

1;

__END__

=head1 NAME

Arch::Test::Tree - A test framework for Arch-Perl

=head1 SYNOPSIS 

    use Arch::Test::Framework;

    my $fw = Arch::Test::Framework->new;
    my $tree = $fw->make_tree($dir, $version);

    my $dir = $tree->add_dir;
    $tree->add_file($dir);
    $tree->import;

=head1 DESCRIPTION

Arch::Test::Tree provides methods to quickly build and modify Arch
project trees within the Arch::Test framework.

=head1 METHODS

B<new>,
B<root>,
B<framework>,
B<run_tla>,
B<add_file>,
B<add_dir>,
B<add_link>,
B<modify_file>,
B<rename_file>,
B<rename_dir>,
B<remove_file>,
B<remove_dir>,
B<inventory>,
B<import>,
B<commit>.

=over 4

=item B<new> [I<framework>] [I<path>]

Create a new Arch::Test::Tree instance for I<path>. This method should
not be called directly.

=item B<root>

Returns the project trees root directory.

=item B<framework>

Returns the associated Arch::Test::Framework reference.

=item B<run_tla> I<@args>

Run C<tla I<@args>> from the tree root.

=item B<add_file> [I<dir> [I<name> [I<content>]]]

Add a new file I<name> in directory I<dir>. Fill file with I<content>.

I<dir> defaults to the project root (C<.>). If I<name> is not
specified, a unique filename is generated. A default content is
generated if none is given.

=item B<add_dir> [I<parent> [I<name>]]

Add a new directory under I<parent>, or C<.> if I<parent> is not
specified. If I<name> is not given, a unique name is generated.

=item B<add_link> [I<parent> [I<name> [I<target>]]]

Add a new symbolic link under I<parent>, or C<.> if I<parent> is not
specified. If I<name> is not given, a unique name is generated. If
I<target> is omitted, a (probably) non-existing target is generated.

=item B<modify_file> I<file> [I<content>]

Change I<file>s content to I<content>, or append C<Has been modified.>
if new content is omitted.

=item B<rename_file> I<old> I<new>

Rename file I<old> to I<new>. Returns I<new>.

=item B<rename_dir> I<old> I<new>

Rename directory I<old> to I<new>. Returns I<new>.

=item B<remove_file> I<file>

Delete I<file> and its associated arch id.

=item B<remove_dir> I<dir>

Recursively delete I<dir> and its content.

=item B<inventory> [I<flags>]

Returns the inventory as generated by running C<tla inventory
I<flags>>. I<flags> default to C<-Bs> if not specified.

=item B<import> [I<summary> [I<log>]]

Create a C<base-0> revision from tree using the summary line
I<summary> and I<log> as log text. If I<tree> contains a log file,
I<summary> and I<log> can be omitted.

=item B<commit> [I<summary> [I<log>]]

Commit a C<patch-n> revision from tree using the summary line
I<summary> and I<log> as log text. If I<tree> contains a log file,
I<summary> and I<log> can be omitted.

=back

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=cut
