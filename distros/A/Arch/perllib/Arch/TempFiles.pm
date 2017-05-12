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

package Arch::TempFiles;

use Exporter;
use vars qw($global_tmp @ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	temp_root temp_name temp_file_name temp_dir_name temp_file temp_dir
);

use Arch::Util qw(remove_dir);

sub new ($) {
	my $class = shift;
	my $self = {
		root  => $ENV{TMP_DIR} || "/tmp",
		files => [],
		dirs  => [],
	};
	return bless $self, $class;
}

sub DESTROY ($) {
	my $self = shift;
	my @temp_files = @{$self->{files}};
	my @temp_dirs = @{$self->{dirs}};

	foreach my $file (@temp_files) {
		unlink($file) || warn "Can't unlink $file: $!\n" if -f $file;
	}
	remove_dir(@temp_dirs) if @temp_dirs;
}

sub root ($;$) {
	my $self = shift;
	$self->{root} = shift if @_;
	return $self->{root};
}

sub name ($;$) {
	my $self = shift;
	my $label = shift || "arch";
	die "Can't make temporary $label name, no valid temp root defined\n"
		unless $self->{root} && -d $self->{root};
	my $prefix = "$self->{root}/,,$label-";
	my $file_name;
	my $tries = 10000;
	do {
		$file_name = $prefix . sprintf("%06d", rand(1000000));
	} while -e $file_name && --$tries;
	die "Failed to acquire unused temp name $prefix*\n" unless $tries;
	return $file_name;
}

sub file_name ($;$) {
	my $self = shift;
	my $file_name = $self->name($_[0]);
	push @{$self->{files}}, $file_name;
	return $file_name;
}

sub dir_name ($;$) {
	my $self = shift;
	my $dir_name = $self->name($_[0]);
	push @{$self->{dirs}}, $dir_name;
	return $dir_name;
}

sub file ($;$) {
	my $self = shift;
	my $file_name = $self->file_name($_[0]);
	# don't create file currently
	return $file_name;
}

sub dir ($;$) {
	my $self = shift;
	my $dir_name = $self->dir_name($_[0]);
	mkdir($dir_name, 0777) and return $dir_name;
	die "Can't mkdir $dir_name: $!" if ($_[1] || 10) <= 1;
	$self->dir($_[0], ($_[1] || 10) - 1);
}

sub _self () {
	return $global_tmp ||= Arch::TempFiles->new;
}

sub temp_root (;$) {
	_self()->root(@_);
}

sub temp_name (;$) {
	_self()->name(@_);
}

sub temp_file_name (;$) {
	_self()->file_name(@_);
}

sub temp_dir_name (;$) {
	_self()->dir_name(@_);
}

sub temp_file (;$) {
	_self()->file(shift);
}

sub temp_dir (;$) {
	_self()->dir(shift);
}

1;

__END__

=head1 NAME

Arch::TempFiles - help to manage temporary files/dirs

=head1 SYNOPSIS 

    use Arch::TempFiles qw(temp_file_name temp_file temp_dir);
    # all will be removed automatically on the script completion
    my $file_name1 = temp_file();
    my $file_name2 = temp_file_name("status");
    my $dir_name = temp_dir("arch-tree");

    use Arch::TempFiles;
    my $tmp = new Arch::TempFiles;
    $tmp->root($tmp->dir);
    my $file_name = $tmp->name;
    open OUT, ">$file_name";
    close OUT;
    
=head1 DESCRIPTION

This module deals with temporary file names. It is similar to L<File::Temp>,
but simplier and more focused. Also, File::Temp is relatively new and was
not shipped with older perl versions.

Both function interface and object oriented interface are supported.

=head1 FUNCTIONS/METHODS

The following functions are available:

B<temp_root>,
B<temp_name>,
B<temp_file_name>,
B<temp_dir_name>,
B<temp_file>,
B<temp_dir>.

The corresponding class methods are available too:

B<root>,
B<name>,
B<file_name>,
B<dir_name>,
B<file>,
B<dir>.

=over 4

=item B<temp_root> [I<dir>]

=item $tmp->B<root> [I<dir>]

Change or return the root of the temporary files and dirs. The default is
either $ENV{TMP_DIR} or "/tmp".

=item B<temp_name> [I<label>]

=item $tmp->B<name> [I<label>]

Return the unused temporary file name. The default file name is
"/tmp/,,arch-XXXXXX" where XXXXXX is a random number. To change this
name use C<temp_root> and/or provide I<label> that replaces "arch".

Please note, that the operation of acquiring the file name using this
function/method and actual creating of this file is not atomic. So you may
need to call this method again if the creation is failed, for example if
some other process created the same file in the middle.

=item B<temp_file_name> [I<label>]

=item $tmp->B<file_name> [I<label>]

Like C<temp_name>, but stores the name in the file list that will be
removed on the end (on object destruction).

=item B<temp_dir_name> [I<label>]

=item $tmp->B<dir_name> [I<label>]

Like C<temp_name>, but stores the name in the dir list that will be
removed on the end (on object destruction).

=item B<temp_file> [I<label>]

=item $tmp->B<file> [I<label>]

Like C<temp_file_name>, but also creates the file.

=item B<temp_dir> [I<label>]

=item $tmp->B<dir> [I<label>]

Like C<temp_dir_name>, but also creates the dir.

=back

=head1 BUGS

Awaiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

=head1 SEE ALSO

For a different interface, see L<File::Temp>.

=cut
