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

package Arch::Tarball;

use Arch::Util qw(run_cmd run_pipe_from copy_dir);
use Arch::TempFiles qw(temp_dir);

sub new ($%) {
	my $class = shift;
	my %init = @_;

	my $self = {
		tar => $init{tar} || "tar",
		file => $init{file},
	};

	bless $self, $class;
	return $self;
}

sub create ($%) {
	my $self = shift;
	my %args = @_;
	my $dir = $args{dir};
	die "Arch::Tarball::create: no dir given\n"
		unless $dir;
	die "Arch::Tarball::create: bad dir ($dir)\n"
		unless -d $dir && $dir =~ s!^(.+)/(.+)$!$1!;
	my $base_name = $2;
	my $needed_base_name = $args{base_name};
	die "Arch::Tarball::create: bad base_name ($needed_base_name)\n"
		if $needed_base_name && $needed_base_name =~ m!/!;
	my $do_pipe = $args{pipe};
	die "Arch::Tarball::create: non-pipe is not implemented yet\n"
		unless $do_pipe;

	if ($needed_base_name && $needed_base_name ne $base_name) {
		my $temp_dir = temp_dir("arch-tarball");
		copy_dir("$dir/$base_name", "$temp_dir/$needed_base_name");
		$base_name = $needed_base_name;
		$dir = $temp_dir;
	}

	my @tar_args = ($self->{tar}, "czf", "-", "-C", $dir, $base_name);
	my $tar_pipe = run_pipe_from(@tar_args);
	return $tar_pipe;
}

sub extract ($%) {
	my $self = shift;
	my %args = @_;

	my $file = $args{file} || $self->{file}
		or die "Arch::Tarball::extract: No file given in constructor\n";
	my $dir = $args{dir} || temp_dir("arch-tarball");
	die "Arch::Tarball::extract: unexisting dir ($dir)\n"
		if $args{dir} && !-d $dir;

	run_cmd($self->{tar}, "xz", "-C", $dir, "-f", $file);

	return $dir;
}

sub list ($%) {
	my $self = shift;
	my %args = @_;
	die "Not implemented yet";
}

1;

__END__

=head1 NAME

Arch::Tarball - an interface to create and work with tarballs

=head1 SYNOPSIS 

    use Arch::Tarball

    my $tarball = Arch::Tarball->new;
    my $pipe = $tarball->create(
        dir => '/path/to/subdir-to-pack',
        base_name => 'new-subdir-to-pack',
        pipe => 1,
    );
    
=head1 DESCRIPTION

Arch::Tarball provides an object oriented interface to work with
(create, examine or extract) standard gzipped tarballs.

B<Note:> As functionality is added only when needed, a lot of features are
currently not implemented.

=head1 METHODS

The following functions are available:

B<new>,
B<create>,
B<extract>,
B<list>.

=over 4

=item B<new> I<%opts>

Creates a new Arch::Tarball object.

The following parameters can be set via I<%opts>:

=over 4

=item B<tar>

The name of the I<tar> executable. Defaults to C<tar>.

=item B<file>

The filename of the Tarball.

=back

=item B<create> I<%opts>

Creates a new tarball (tar.gz) from a given directory structure.

B<create> understands the following options:

=over 4

=item B<dir> (mandatory)

Specifies the base directory for the tarball. The given directory and
recursively its content will be added to the tarball. The directory's
basename will be used as the first and the only subdirectory in the tarball.

=item B<base_name>

Allow the programmer to specify a different base directory name for the
tarball content than the basename of B<dir>. In this case,
'cp' process is launched to temporarily rename the last element of B<dir>.

=item B<pipe>

When set, B<create> does not create a physical tarball but writes the
tarballs content to a newly created pipe. The pipe is returned by the
B<create> method.

=back

B<Note:> Currently the B<pipe> option is mandatory.

=item B<extract> I<%opts>

Extracts the tarball to a given target directory, specified by B<dir> option.
If B<dir> option is not given, a temporary directory is created that will
hold the extracted dirs/files. This directory is returned.

The B<file> option specifies the tarball file name. It may be given in the
constructor instead.

=item B<list> I<%opts> (not implemented yet)

Returns a list of files and directories in the tarball.

=back

=head1 BUGS

Most functionality is currently not implemented. If you need part of
the missing functionality, please contact the authors.

Patches are greatly appreciated.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=cut
