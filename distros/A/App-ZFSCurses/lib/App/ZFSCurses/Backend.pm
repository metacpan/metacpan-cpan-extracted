package App::ZFSCurses::Backend;

use warnings;
use strict;
use 5.10.1;

=head1 NAME

App::ZFSCurses::Backend - Perform backend operations.

=cut

=head1 VERSION

Version 1.212.

=cut

our $VERSION = '1.212';

=head1 METHODS

=head2 new

Create an instance of App::ZFSCurses::Backend.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 is_zfs_installed

Run the `zfs' command using qx and return the return code.

=cut

sub is_zfs_installed {
    my $self = shift;
    return do {
        qx#zfs 2>&1#;
        $?;
    };
}

=head2 get_zfs_datasets

Return ZFS datasets found on the system. This method runs
"zfs list -t filesystem" behind the scenes.

=cut

sub get_zfs_datasets {
    my $self = shift;

    my @zfs_list_args = ( 'zfs', 'list', '-t', 'filesystem' );
    my @zfs_datasets  = ();

    {
        open( my $zfs_list_fh, '-|', @zfs_list_args )
          or die "can't run @zfs_list_args: $!";

        while (<$zfs_list_fh>) {
            chomp;
            push @zfs_datasets, $_;
        }
    }

    return [ grep { !m/^.*?none$/ } sort @zfs_datasets ];
}

=head2 get_zfs_snapshots

Return ZFS snapshots found on the system. This method runs "zfs list -t
snapshot" behind the scenes.

=cut

sub get_zfs_snapshots {
    my $self = shift;

    my @zfs_list_args = ( 'zfs', 'list', '-t', 'snapshot' );
    my @zfs_snapshots = ();

    {
        open( my $zfs_list_fh, '-|', @zfs_list_args )
          or die "can't run @zfs_list_args: $!";

        while (<$zfs_list_fh>) {
            chomp;
            push @zfs_snapshots, $_;
        }
    }

    return [ grep { !m/^.*?none$/ } sort @zfs_snapshots ];
}

=head2 get_zfs_properties

Return ZFS properties for a given dataset. This method expects a dataset as
first argument.

=cut

sub get_zfs_properties {
    my $self = shift;

    @_ == 1 || die qq#Usage: get_zfs_properties(dataset)#;
    my $dataset = shift;

    my @zfs_get_args   = ( 'zfs', 'get', 'all', $dataset );
    my @zfs_properties = ();

    {
        open( my $zfs_get_fh, '-|', @zfs_get_args )
          or die "can't run @zfs_get_args: $!";

        while (<$zfs_get_fh>) {
            chomp;
            my $properties = ( split /^(.*?)(\s+)(.*?)$/, $_ )[3];

            # Unsupported properties on FreeBSD.
            # See man zfs.
            if ( $^O eq 'freebsd' ) {
                next
                  if ( $properties =~ /(mlslabel|devices|nbmand|xattr|vscan)/ );
            }

            push @zfs_properties, $properties;
        }
    }

    return [ sort @zfs_properties ];
}

=head2 set_zfs_property

Set property to a given ZFS dataset.

This method expects three arguments:

=over 3

=item *
a dataset

=item *
a property

=item *
a value

=back

=cut

sub set_zfs_property {
    my $self = shift;
    @_ == 3 || die qq#Usage: set_zfs_property(dataset, property, value)#;

    my ( $dataset, $property, $value ) = @_;
    my @zfs_set_args = ( 'zfs', 'set', "$property=$value", "$dataset" );

    open( my $zfs_set_fh, '-|', @zfs_set_args )
      or die "can't run @zfs_set_args: $!";

    close $zfs_set_fh;
}

=head2 destroy_zfs

Destroy a given object: snapshot, dataset, volume.

=cut

sub destroy_zfs {
    my $self = shift;

    @_ == 1 || die qq#Usage: destroy_zfs(object)#;
    my $object = shift;

    my @zfs_destroy_args = ( 'zfs', 'destroy', '-r', $object );

    open( my $zfs_destroy_fh, '-|', @zfs_destroy_args )
      or die "can't run @zfs_destroy_args $!";

    close $zfs_destroy_fh;
}

=head1 SEE ALSO

The L<FreeBSD documentation on ZFS|https://www.freebsd.org/doc/handbook/zfs.html>.

=head1 AUTHOR

Patrice Clement <monsieurp at cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Patrice Clement.

This is free software, licensed under the (three-clause) BSD License.

See the LICENSE file.

=cut

1;
