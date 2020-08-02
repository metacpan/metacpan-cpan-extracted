package App::ZFSCurses::Backend;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::ZFSCurses::Backend - Perform backend operations.

=cut

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

    my @zfs_datasets = ();

    open( ZFS_LIST_PIPE, '-|', @zfs_list_args )
      or die "can't run @zfs_list_args: $!";

    while (<ZFS_LIST_PIPE>) {
        chomp;
        push @zfs_datasets, $_;
    }

    close ZFS_LIST_PIPE;

    return [ grep { !m/^.*?none$/ } sort @zfs_datasets ];
}

=head2 get_zfs_properties

Return ZFS properties for a given dataset. This method expects a dataset as
first argument.

=cut

sub get_zfs_properties {
    my $self = shift;

    @_ == 1 || die qq#Usage: get_zfs_properties(dataset)#;
    my $dataset = shift;

    my @zfs_get_args = ( 'zfs', 'get', 'all', $dataset );

    my @zfs_properties = ();

    open( ZFS_GET_PIPE, '-|', @zfs_get_args )
      or die "can't run @zfs_get_args: $!";

    while (<ZFS_GET_PIPE>) {
        chomp;
        my $properties = ( split /^(.*?)(\s+)(.*?)$/, $_ )[3];

        # Unsupported properties on FreeBSD.
        # See man zfs.
        if ( $^O eq 'freebsd' ) {
            next if ( $properties =~ /(mlslabel|devices|nbmand|xattr|vscan)/ );
        }

        push @zfs_properties, $properties;
    }

    close ZFS_GET_PIPE;

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

    open( ZFS_SET_PIPE, '-|', @zfs_set_args )
      or die "can't run @zfs_set_args: $!";

    close ZFS_SET_PIPE;
}

=head1 AUTHOR

Patrice Clement <monsieurp at cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Patrice Clement.

This is free software, licensed under the (three-clause) clause BSD License.

See the LICENSE file.

=cut

1;
