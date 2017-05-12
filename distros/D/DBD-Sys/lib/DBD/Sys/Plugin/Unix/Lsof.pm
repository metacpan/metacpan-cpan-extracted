package DBD::Sys::Plugin::Unix::Lsof;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

$VERSION  = "0.102";
@colNames = qw(pid ppid pgrp uid username command filename filetype inode linkcount mountpoint);

=pod

=head1 NAME

DBD::Sys::Plugin::Unix::Lsof - provides a table containing open files

=head1 SYNOPSIS

  $openfiles = $dbh->selectall_hashref("select * from openfiles", ["pid","filename"]);

=head1 ISA

  DBD::Sys::Plugin::Unix::Lsof;
  ISA DBD::Sys::Table

=head1 DESCRIPTION

This module provides the table I<openfiles> filled with the list of open
files.

=head2 COLUMNS

=head3 pid

Process ID of the process opened the file

=head3 ppid

Parent process ID of the process opened the file

=head3 pgrp

Process Group ID of the process opened the file

=head3 uid

User ID

=head3 username

Name of the user who owns the process which has opened the file

=head3 command

executed command (process executable)

=head3 filename

Full qualified path name of the open file

=head3 filetype

File type (VDIR, VREG, ...) of the open file

=head3 inode

Inode number of the open file

=head3 linkcount

Link count of the open file

=head3 mountpoint

Mount point of the file system where the file resides

=head1 METHODS

=head2 get_table_name

Returns 'grent'.

=cut

sub get_table_name() { return 'openfiles'; }

=head2 get_col_names

Returns the column names of the table as named in L</Columns>

=cut

sub get_col_names() { @colNames }

=head2 get_attributes

Return the attributes supported by this module:

=head3 uids

Allows restricting the user ids (see lsof(8) for the C<-u> parameter).

    $dbh->{sys_openfiles_uids} = [scalar getpwuid $<];
    $dbh->{sys_openfiles_uids} = [$<]; # all opened by myself

=head3 pids

Allows restricting the process ids (see lsof(8) for the C<-p> parameter).

    $dbh->{sys_openfiles_pids} = ['^' . $$]; # everything except the current process

=head3 filesys

Allows restricting the scanned file systems (see lsof(8) for the C<+f>
parameter).

    $dbh->{sys_openfiles_filesys} = [qw(/usr /var)];

=cut

sub get_attributes() { return qw(uids pids filesys) }

my $havelsof;
my $havesysfsmountpoint;

=head2 collect_data

Retrieves the data from the lsof command and put it into fetchable rows.

=cut

sub collect_data()
{
    my $self = $_[0];
    my @data;

    unless ( defined($havelsof) )
    {
        $havelsof = 0;
        eval {
            require Unix::Lsof;
            $havelsof = 1;
        };
    }

    unless ( defined($havesysfsmountpoint) )
    {
        $havesysfsmountpoint = 0;
        eval {
            require Sys::Filesystem::MountPoint;
            $havesysfsmountpoint = 1;
        };
    }

    if ($havelsof)
    {
        my @args;
        if ( $self->{meta}->{uids} )
        {
            push( @args, '-u' );
            push( @args,
                  ref( $self->{meta}->{uids} ) eq 'ARRAY'
                  ? join( ',', @{ $self->{meta}->{uids} } )
                  : $self->{meta}->{uids} );
        }
        if ( $self->{meta}->{pids} )
        {
            push( @args, '-p' );
            push( @args,
                  ref( $self->{meta}->{pids} ) eq 'ARRAY'
                  ? join( ',', @{ $self->{meta}->{pids} } )
                  : $self->{meta}->{pids} );
        }
        if ( $self->{meta}->{filesys} )
        {
            push( @args,
                  ref( $self->{meta}->{filesys} ) eq 'ARRAY'
                  ? @{ $self->{meta}->{uids} }
                  : $self->{meta}->{filesys} );
        }

        my ( $output, $error ) = Unix::Lsof::lsof(@args);
        foreach my $pid ( keys %{$output} )
        {
            my $pinfo   = $output->{$pid};
            my @pfields = @$pinfo{
                'process id',
                'parent pid',
                'process group id',
                'user id',
                'login name',
                'command name'
              };
            foreach my $pfile ( @{ $pinfo->{files} } )
            {
                my @row =
                  ( @pfields, @$pfile{ 'file name', 'file type', 'inode number', 'link count' } );
                push( @row,
                      $havesysfsmountpoint
                      ? Sys::Filesystem::MountPoint::path_to_mount_point( $pfile->{'file name'} )
                      : undef );
                push( @data, \@row );
            }
        }
    }

    return \@data;
}

=head1 PREREQUISITES

The module L<Unix::Lsof> is required to provide data for the table. The
column mountpoint can be filled only if the module
L<Sys::Filesystem::MountPoint> is installed.

=head1 AUTHOR

    Jens Rehsack
    CPAN ID: REHSACK
    rehsack@cpan.org
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
