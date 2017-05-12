package DBD::Sys::Plugin::Any::FileSysDf;

use strict;
use warnings;

use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

=pod

=head1 NAME

DBD::Sys::Plugin::Any::FileSysDf - provides a table containing the free space of file systems

=head1 SYNOPSIS

  $filesysdf = $dbh->selectall_hashref("select * from filesysdf", "mountpoint");

=head1 ISA

  DBD::Sys::Plugin::Any::FileSysDf
  ISA DBD::Sys::Table

=cut

my $haveFilesysDf;

$VERSION  = "0.102";
@colNames = qw(mountpoint blocks bfree bavail bused bper files ffree favail fused fper);

=head1 DESCRIPTION

This module provides the table <filesysdf> which contains the free space
on file systems.

=head2 COLUMNS

=head3 mountpoint

The friendly name of the filesystem. This will usually be the same
name as appears in the list returned by the filesystems() method.

=head3 blocks

Total blocks existing on the filesystem.

=head3 bfree

Total blocks free existing on the filesystem.

=head3 bavail

Total blocks available to the user executing the Perl application.
This can be different than C<bfree> if you have per-user quotas on
the filesystem, or if the super user has a reserved amount.
C<bavail> can also be a negative value because of this. For instance
if there is more space being used then you have available to you.

=head3 bused

Total blocks used existing on the filesystem.

=head3 bper

Percent of disk space used. This is based on the disk space available
to the user executing the application. In other words, if the filesystem
has 10% of its space reserved for the superuser, then the percent used
can go up to 110%.

=head3 files

Total inodes existing on the filesystem.

=head3 ffree

Total inodes free existing on the filesystem.

=head3 favail

Total inodes available to the user executing the application.
See the information for the C<bavail> column.

=head3 fused

Total inodes used existing on the filesystem.

=head3 fper

Percent of inodes used on the filesystem.
See the information for the C<bper> column.

=head1 METHODS

=head2 get_col_names

Returns the column names of the table as named in L</Columns>

=cut

sub get_col_names() { return @colNames }

=head2 get_attributes

Return the attributes supported by this module:

=head3 blocksize

Allows to specify the blocksize of the returned free blocks.
This defaults to 1.

    $dbh->{sys_filesysdf_blocksize} = 512; # use UNIX typical blocksize for df

=cut

sub get_attributes() { return qw(blocksize) }

=head2 collect_data

Retrieves the mountpoints of mounted file systems from L<Sys::Filesystem>
and determine the free space on their devices using L<Filesys::DfPortable>.
The mountpoint and the free space information are put in fetchable rows.

=cut

sub collect_data()
{
    my $self = $_[0];
    my @data;

    unless ( defined($haveFilesysDf) )
    {
        $haveFilesysDf = 0;
        eval {
            require Sys::Filesystem;
            require Filesys::DfPortable;
            $haveFilesysDf = 1;
        };
        Filesys::DfPortable->import() if ($haveFilesysDf);
    }

    if ($haveFilesysDf)
    {
        my $fs          = Sys::Filesystem->new();
        my @filesystems = $fs->filesystems( mounted => 1 );
        my $blocksize   = $self->{meta}->{blocksize} || 1;

        foreach my $filesys (@filesystems)
        {
            my @row;
            my $mountpt = $fs->mount_point($filesys);
            my $df = dfportable( $mountpt, $blocksize );
            if ( defined($df) )
            {
                @row = (
                         $fs->mount_point($filesys),
                         @$df{
                             'blocks', 'bfree',  'bavail', 'bused', 'per', 'files',
                             'ffree',  'favail', 'fused',  'fper'
                           }
                       );
            }
            else
            {
                @row = ( $fs->mount_point($filesys), (undef) x 10 );
            }
            push( @data, \@row );
        }
    }

    return \@data;
}

=head1 PREREQUISITES

L<Sys::Filesystem> and L<Filesys::DfPortable> are required in order to
fill the table C<filesysdf> with data.

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
