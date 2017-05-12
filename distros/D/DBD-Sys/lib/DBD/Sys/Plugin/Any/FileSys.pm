package DBD::Sys::Plugin::Any::FileSys;

use strict;
use warnings;

use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

=pod

=head1 NAME

DBD::Sys::Plugin::Any::FileSys - provides a table containing file systems

=head1 SYNOPSIS

  $filesystems = $dbh->selectall_hashref("select * from filesystems", "mountpoint");

=head1 ISA

  DBD::Sys::Plugin::Any::FileSys
  ISA DBD::Sys::Table

=cut

my $haveSysFs;

$VERSION  = "0.102";
@colNames = qw(mountpoint mounted label volume device special type options);

=head1 DESCRIPTION

This module provides the table C<filesystems> for any operating system.

=head2 COLUMNS

=head3 mountpoint

The friendly name of the filesystem. This will usually be the same
name as appears in the list returned by the filesystems() method.

=head3 mounted

Boolean, true if the filesystem is mounted.

=head3 label

The fileystem label

=head3 volume

Volume that the filesystem belongs to or is mounted on.

=head3 device

The physical device that the filesystem is connected to.

=head3 special

Boolean true if the filesystem type is considered "special".

=head3 type

The type of filesystem format, e.g. fat32, ntfs, ufs, hpfs, ext3, xfs etc.

=head3 options

The options that the filesystem was mounted with.
This may commonly contain information such as read-write,
user and group settings and permissions.

=head1 METHODS

=head2 get_col_names

Returns the column names of the table as named in L</Columns>

=cut

sub get_col_names() { @colNames }

=head2 get_table_name

Returns 'filesystems'

=cut

sub get_table_name() { return 'filesystems'; }

=head2 collect_data

Retrieves the data from L<Sys::Filesystem> and put it into fetchable rows.

=cut

sub collect_data()
{
    my @data;

    unless ( defined($haveSysFs) )
    {
        $haveSysFs = 0;
        eval {
            require Sys::Filesystem;
            $haveSysFs = 1;
        };
    }

    if ($haveSysFs)
    {
        my $fs          = Sys::Filesystem->new();
        my @filesystems = $fs->filesystems();

        foreach my $filesys (@filesystems)
        {
            my @row;
            @row = (
                     $fs->mount_point($filesys), $fs->mounted($filesys),
                     $fs->label($filesys),       $fs->volume($filesys),
                     $fs->device($filesys),      $fs->special($filesys),
                     $fs->type($filesys),        $fs->options($filesys)
                   );
            push( @data, \@row );
        }
    }

    return \@data;
}

=head1 PREREQUISITES

L<Sys::Filesystem> is required to use this table.

=head1 AUTHOR

    Jens Rehsack			Alexander Breibach
    CPAN ID: REHSACK
    rehsack@cpan.org			alexander.breibach@googlemail.com
    http://www.rehsack.de/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SUPPORT

Free support can be requested via regular CPAN bug-tracking system. There is
no guaranteed reaction time or solution time, but it's always tried to give
accept or reject a reported ticket within a week. It depends on business load.
That doesn't mean that ticket via rt aren't handles as soon as possible,
that means that soon depends on how much I have to do.

Business and commercial support should be acquired from the authors via
preferred freelancer agencies.

=cut

1;
