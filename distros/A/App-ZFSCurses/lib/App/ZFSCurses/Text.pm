package App::ZFSCurses::Text;

use 5.006;
use strict;
use warnings;

use Text::Wrap;
$Text::Wrap::columns = 80;

=head1 NAME

App::ZFSCurses::Text - UI texts and messages.

=cut

=head1 METHODS

=head2 new

Create an instance of App::ZFSCurses::Text.

=cut

sub new {
    my $class = shift;
    my %args  = ( help_messages => {} );
    my $this  = bless \%args, $class;
    $this->fill_help_messages();
    return $this;
}

=head2 title

Return the text title.

=cut

sub title {
    return 'ZFScurses';
}

=head2 top_label_datasets

Return the top label text in the dataset screen.

=cut

sub top_label_datasets {
    return "List of all ZFS datasets found on your system.\n"
      . "Please select a dataset:";
}

=head2 top_label_properties

Return the top label text in the properties screen.

=cut

sub top_label_properties {
    my $self    = shift;
    my $dataset = shift;
    return "List of ZFS properties for the \"$dataset\" dataset.\n"
      . "Please select a property to change:";
}

=head2 footer

Return the footer text. This method expects (sometimes) a text about the F1
key.

=cut

sub footer {
    my $self = shift;
    my $f1   = shift;
    my $help =
        "[Up/Down] Move cursor up/down. "
      . "[Enter/Space] Validate. "
      . "[Tab] Change focus. "
      . "\n[Ctrl+q] Quit. ";
    if ( defined $f1 ) { $help .= "$f1"; }
    return $help;
}

=head2 exit_dialog

Return the exit dialog text.

=cut

sub exit_dialog {
    return 'Quit ZFScurses?';
}

=head2 f1_help

Return the text about the F1 key. This method is given to the footer method
depending on the screen displayed to the user.

=cut

sub f1_help {
    return "[F1] Show help for selected property.";
}

=head2 select_property

Return the text when a property is not selected.

=cut

sub select_property {
    return 'Please select a property!';
}

=head2 select_dataset

Return the text when a dataset is not selected.

=cut

sub select_dataset {
    return 'Please select a dataset!';
}

=head2 change_property

Return the text label displayed in the change properties screen.

=cut

sub change_property {
    my $self = shift;
    my ( $dataset, $property, $value ) = @_;
    return
      "Dataset \"$dataset\" has the property \"$property\" set to \"$value\".\n"
      . "Set a new value. OK to confirm. Cancel to go back to previous screen.";
}

=head2 ok_property

Return the text when a property has been changed.

=cut

sub ok_property {
    my $self     = shift;
    my $property = shift;
    return "Property \"$property\" changed successfully!";
}

=head2 error_property

Return the text when an error occured while changing a property.

=cut

sub error_property {
    my $self     = shift;
    my $property = shift;
    return "Could not change property \"$property\"!";
}

=head2 no_help_found

Return the text when no help has been found for a property.

=cut

sub no_help_found {
    my $self     = shift;
    my $property = shift;
    return "No help found for property \"$property\".";
}

=head2 no_zfs_command_found

Return the text when the zfs command hasn't been found.

=cut

sub no_zfs_command_found {
    my $self = shift;
    return "ERROR! ZFScurses cannot work without a ZFS filesystem!";
}

=head2 non_root_user

Return the text when zfscurses is run without root privileges.

=cut

sub non_root_user {
    return "WARNING! ZFScurses runs without root privileges!\n"
      . "You will not be able to change datasets properties.";
}

=head2 property_read_only

Return the text when a property is read only.

=cut

sub property_read_only {
    my $self     = shift;
    my $property = shift;
    return "Property \"$property\" is read only!";
}

=head2 fill_help_messages

Read the __DATA__ handle and fill the help_messages hash with property
definitions.  The __DATA__ handle is filled with lines that look like this:

  aclinherit%aclinherit is a property that is about ...

The idea is to split the line on the % part and then fill the hash with the
property and its definition. The hash is then called upon when the F1 key is
pressed to display to the user what a property is about.

This method is called automatically after instantiating this class.

=cut

sub fill_help_messages {
    my $self = shift;
    while (<DATA>) {
        chomp;
        my ( $property, $definition ) = split /%/;
        my $help = "What is the \"$property\" property for?\n\n$definition";
        $self->{help_messages}->{$property} = wrap( '', '', $help );
    }
}

=head2 help_messages

Return the help_messages hash.

=cut

sub help_messages {
    my $self = shift;
    return $self->{help_messages};
}

=head1 AUTHOR

Patrice Clement <monsieurp at cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Patrice Clement.

This is free software, licensed under the (three-clause) clause BSD License.

See the LICENSE file.

=cut

1;

__DATA__
available%The amount of space available to the dataset and all its children, assuming that there is no other activity in the pool. Because space is shared within a pool, availability can be limited by any number of factors, including physical pool size, quotas, reservations, or other datasets within the pool.
compressratio%For non-snapshots, the compression ratio achieved for the used space of this dataset, expressed as a multiplier. The used property includes descendant datasets, and, for clones, does not include the space shared with the origin snapshot. For snapshots, the compressratio is the same as the refcompressratio property. Compression can be turned on by running: "zfs set compression=on dataset" The default value is off.
createtxg%The transaction group (txg) in which the dataset was created. Bookmarks have the same createtxg as the snapshot they are initially tied to. This property is suitable for ordering a list of snapshots, e.g. for incremental send and receive.
creation%The time this dataset was created.
clones%For snapshots, this property is a comma-separated list of filesystems or volumes which are clones of this snapshot. The clones' origin property is this snapshot. If the clones property is not empty, then this snapshot can not be destroyed (even with the -r or -f options).
defer_destroy%This property is on if the snapshot has been marked for deferred destroy by using the "zfs destroy -d" command. Otherwise, the property is off.
filesystem_count%The total number of filesystems and volumes that exist under this location in the dataset tree. This value is only available when a filesystem_limit has been set somewhere in the tree under which the dataset resides.
guid%The 64 bit GUID of this dataset or bookmark which does not change over its entire lifetime. When a snapshot is sent to another pool, the received snapshot has the same GUID. Thus, the guid is suitable to identify a snapshot across pools.
logicalreferenced%The amount of space that is "logically" accessible by this dataset. See the referenced property. The logical space ignores the effect of the compression and copies properties, giving a quantity closer to the amount of data that applications see. However, it does include space consumed by metadata.
logicalused%The amount of space that is "logically" consumed by this dataset and all its descendents. See the used property. The logical space ignores the effect of the compression and copies properties, giving a quantity closer to the amount of data that applications see.
mounted%For file systems, indicates whether the file system is currently mounted. This property can be either yes or no.
origin%For cloned file systems or volumes, the snapshot from which the clone was created. See also the clones property.
receive_resume_token%For filesystems or volumes which have saved partially-completed state from zfs receive -s, this opaque token can be provided to zfs send -t to resume and complete the zfs receive.
referenced%The amount of data that is accessible by this dataset, which may or may not be shared with other datasets in the pool. When a snapshot or clone is created, it initially references the same amount of space as the file system or snapshot it was created from, since its contents are identical.
refcompressratio%The compression ratio achieved for the referenced space of this dataset, expressed as a multiplier. See also the compressratio property.
snapshot_count%The total number of snapshots that exist under this location in the dataset tree. This value is only available when a snapshot_limit has been set somewhere in the tree under which the dataset resides.
type%The type of dataset: filesystem, volume, or snapshot.
used%The amount of space consumed by this dataset and all its descendents. This is the value that is checked against this dataset's quota and reservation. The space used does not include this dataset's reservation, but does take into account the reservations of any descendent datasets. The amount of space that a dataset consumes from its parent, as well as the amount of space that are freed if this dataset is recursively destroyed, is the greater of its space used and its reservation.
usedby%The usedby properties decompose the used properties into the various reasons that space is used. Specifically, used = usedbysnapshots + usedbydataset + usedbychildren + usedbyrefreservation. These properties are only available for datasets created with ZFS pool version 13 pools and higher.
usedbysnapshots%The amount of space consumed by snapshots of this dataset. In particular, it is the amount of space that would be freed if all of this dataset's snapshots were destroyed. Note that this is not simply the sum of the snapshots' used properties because space can be shared by multiple snapshots.
usedbydataset%The amount of space used by this dataset itself, which would be freed if the dataset were destroyed (after first removing any refreservation and destroying any necessary snapshots or descendents).
usedbychildren%The amount of space used by children of this dataset, which would be freed if all the dataset's children were destroyed.
usedbyrefreservation%The amount of space used by a refreservation set on this dataset, which would be freed if the refreservation was removed.
userrefs%This property is set to the number of user holds on this snapshot. User holds are set by using the "zfs hold" command.
volblocksize%For volumes, specifies the block size of the volume. The blocksize cannot be changed once the volume has been written, so it should be set at volume creation time. The default blocksize for volumes is 8 Kbytes. Any power of 2 from 512 bytes to 128 Kbytes is valid.
written%The amount of referenced space written to this dataset since the previous snapshot.
aclinherit%Controls how ACL entries are inherited when files and directories are created. A file system with an aclinherit property of discard does not inherit any ACL entries. A file system with an aclinherit property value of noallow only inherits inheritable ACL entries that specify "deny" permissions. The property value restricted (the default) removes the write_acl and write_owner permissions when the ACL entry is inherited. A file system with an aclinherit property value of passthrough inherits all inheritable ACL entries without any modifications made to the ACL entries when they are inherited. A file system with an aclinherit property value of passthrough-x has the same meaning as passthrough, except that the owner@, group@, and everyone@ ACEs inherit the execute permission only if the file creation mode also requests the execute bit. When the property value is set to passthrough, files are created with a mode determined by the inheritable ACEs. If no inheritable ACEs exist that affect the mode, then the mode is set in accordance to the requested mode from the application.
aclmode%Controls how an ACL is modified during chmod(2). A file system with an aclmode property of discard (the default) deletes all ACL entries that do not represent the mode of the file. An aclmode property of groupmask reduces permissions granted in all ALLOW entries found in the ACL such that they are no greater than the group permissions specified by chmod(2). A file system with an aclmode property of passthrough indicates that no changes are made to the ACL other than creating or updating the necessary ACL entries to represent the new mode of the file or directory. An aclmode property of restricted will cause the chmod(2) operation to return an error when used on any file or directory which has a non-trivial ACL whose entries can not be represented by a mode. chmod(2) is required to change the set user ID, set group ID, or sticky bits on a file or directory, as they do not have equivalent ACL entries. In order to use chmod(2) on a file or directory with a non-trivial ACL when aclmode is set to restricted, you must first remove all ACL entries which do not represent the current mode.
atime%Controls whether the access time for files is updated when they are read. Turning this property off avoids producing write traffic when reading files and can result in significant performance gains, though it might confuse mailers and other similar utilities. The default value is on.
canmount%If this property is set to off, the file system cannot be mounted, and is ignored by "zfs mount -a". Setting this property to off is similar to setting the mountpoint property to none, except that the dataset still has a normal mountpoint property, which can be inherited. Setting this property to off allows datasets to be used solely as a mechanism to inherit properties. One example of setting canmount=off is to have two datasets with the same mountpoint, so that the children of both datasets appear in the same directory, but might have different inherited characteristics. When the noauto value is set, a dataset can only be mounted and unmounted explicitly. The dataset is not mounted automatically when the dataset is created or imported, nor is it mounted by the "zfs mount -a" command or unmounted by the "zfs umount -a" command.
checksum%Controls the checksum used to verify data integrity. The default value is on, which automatically selects an appropriate algorithm (currently, fletcher4, but this may change in future releases). The value off disables integrity checking on user data. The value noparity not only disables integrity but also disables maintaining parity for user data. This setting is used internally by a dump device residing on a RAID-Z pool and should not be used by any other dataset. Disabling checksums is NOT a recommended practice. The sha512, and skein checksum algorithms require enabling the appropriate features on the pool. Please see zpool-features(7) for more information on these algorithms. Changing this property affects only newly-written data. Salted checksum algorithms (edonr, skein) are currently not supported for any filesystem on the boot pools.
compression%Controls the compression algorithm used for this dataset. Setting compression to on indicates that the current default compression algorithm should be used. The default balances compression and decompression speed, with compression ratio and is expected to work well on a wide variety of workloads. Unlike all other settings for this property, on does not select a fixed compression type. As new compression algorithms are added to ZFS and enabled on a pool, the default compression algorithm may change. The current default compression algorthm is either lzjb or, if the lz4_compress feature is enabled, lz4. The lzjb compression algorithm is optimized for performance while providing decent data compression. Setting compression to on uses the lzjb compression algorithm. The gzip compression algorithm uses the same compression as the gzip(1) command. You can specify the gzip level by using the value gzip-N where N is an integer from 1 (fastest) to 9 (best compression ratio). Currently, gzip is equivalent to gzip-6 (which is also the default for gzip(1)). The zle compression algorithm compresses runs of zeros. The lz4 compression algorithm is a high-performance replacement for the lzjb algorithm. It features significantly faster compression and decompression, as well as a moderately higher compression ratio than lzjb, but can only be used on pools with the lz4_compress feature set to enabled. See zpool-features(7) for details on ZFS feature flags and the lz4_compress feature. This property can also be referred to by its shortened column name compress. Changing this property affects only newly-written data.
copies%Controls the number of copies of data stored for this dataset. These copies are in addition to any redundancy provided by the pool, for example, mirroring or RAID-Z. The copies are stored on different disks, if possible. The space used by multiple copies is charged to the associated file and dataset, changing the used property and counting against quotas and reservations. Changing this property only affects newly-written data. Therefore, set this property at file system creation time by using the -o copies=N option.
dedup%Configures deduplication for a dataset. The default value is off. The default deduplication checksum is sha256 (this may change in the future). When dedup is enabled, the checksum defined here overrides the checksum property. Setting the value to verify has the same effect as the setting sha256,verify. If set to verify, ZFS will do a byte-to-byte comparsion in case of two blocks having the same signature to make sure the block contents are identical.
exec%Controls whether processes can be executed from within this file system. The default value is on.
mlslabel%The mlslabel property is currently not supported on FreeBSD.
filesystem_limit%Limits the number of filesystems and volumes that can exist under this point in the dataset tree. The limit is not enforced if the user is allowed to change the limit. Setting a filesystem_limit on a descendent of a filesystem that already has a filesystem_limit does not override the ancestor's filesystem_limit, but rather imposes an additional limit. This feature must be enabled to be used (see zpool-features(7)).
mountpoint%Controls the mount point used for this file system. See the "Mount Points" section for more information on how this property is used. When the mountpoint property is changed for a file system, the file system and any children that inherit the mount point are unmounted. If the new value is legacy, then they remain unmounted. Otherwise, they are automatically remounted in the new location if the property was previously legacy or none, or if they were mounted before the property was changed. In addition, any shared file systems are unshared and shared in the new location.
primarycache%Controls what is cached in the primary cache (ARC). If this property is set to all, then both user data and metadata is cached. If this property is set to none, then neither user data nor metadata is cached. If this property is set to metadata, then only metadata is cached. The default value is all.
quota%Limits the amount of space a dataset and its descendents can consume. This property enforces a hard limit on the amount of space used. This includes all space consumed by descendents, including file systems and snapshots. Setting a quota on a descendent of a dataset that already has a quota does not override the ancestor's quota, but rather imposes an additional limit.  Quotas cannot be set on volumes, as the volsize property acts as an implicit quota.
snapshot_limit%Limits the number of snapshots that can be created on a dataset and its descendents. Setting a snapshot_limit on a descendent of a dataset that already has a snapshot_limit does not override the ancestor's snapshot_limit, but rather imposes an additional limit. The limit is not enforced if the user is allowed to change the limit. For example, this means that recursive snapshots taken from the global zone are counted against each delegated dataset within a jail. This feature must be enabled to be used (see zpool-features(7)).
readonly%Controls whether this dataset can be modified. The default value is off.
recordsize%Specifies a suggested block size for files in the file system. This property is designed solely for use with database workloads that access files in fixed-size records. ZFS automatically tunes block sizes according to internal algorithms optimized for typical access patterns. For databases that create very large files but access them in small random chunks, these algorithms may be suboptimal. Specifying a recordsize greater than or equal to the record size of the database can result in significant performance gains. Use of this property for general purpose file systems is strongly discouraged, and may adversely affect performance. The size specified must be a power of two greater than or equal to 512 and less than or equal to 128 Kbytes. If the large_blocks feature is enabled on the pool, the size may be up to 1 Mbyte. See zpool-features(7) for details on ZFS feature flags. Changing the file system's recordsize affects only files created afterward; existing files are unaffected.
redundant_metadat%Controls what types of metadata are stored redundantly. ZFS stores an extra copy of metadata, so that if a single block is corrupted, the amount of user data lost is limited. This extra copy is in addition to any redundancy provided at the pool level (e.g. by mirroring or RAID-Z), and is in addition to an extra copy specified by the copies property (up to a total of 3 copies). For example if the pool is mirrored, copies=2, and redundant_metadata=most, then ZFS stores 6 copies of most metadata, and 4 copies of data and some metadata. When set to all, ZFS stores an extra copy of all metadata. If a single on-disk block is corrupt, at worst a single block of user data (which is recordsize bytes long can be lost.). When set to most, ZFS stores an extra copy of most types of metadata. This can improve performance of random writes, because less metadata must be written. In practice, at worst about 100 blocks (of recordsize bytes each) of user data can be lost if a single on-disk block is corrupt. The exact behavior of which metadata blocks are stored redundantly may change in future releases. The default value is all.
refquota%Limits the amount of space a dataset can consume. This property enforces a hard limit on the amount of space used. This hard limit does not include space used by descendents, including file systems and snapshots.
refreservation%The minimum amount of space guaranteed to a dataset, not including its descendents. When the amount of space used is below this value, the dataset is treated as if it were taking up the amount of space specified by refreservation. The refreservation reservation is accounted for in the parent datasets' space used, and counts against the parent datasets' quotas and reservations. If refreservation is set, a snapshot is only allowed if there is enough free pool space outside of this reservation to accommodate the current number of "referenced" bytes in the dataset. If refreservation is set to auto, a volume is thick provisioned or not sparse. refreservation= auto is only supported on volumes. See volsize in the Native Properties section for more information about sparse volumes.
reservation%The minimum amount of space guaranteed to a dataset and its descendents. When the amount of space used is below this value, the dataset is treated as if it were taking up the amount of space specified by its reservation. Reservations are accounted for in the parent datasets' space used, and count against the parent datasets' quotas and reservations.
secondarycache%Controls what is cached in the secondary cache (L2ARC). If this property is set to all, then both user data and metadata is cached. If this property is set to none, then neither user data nor metadata is cached. If this property is set to metadata, then only metadata is cached. The default value is all.
setuid%Controls whether the set-UID bit is respected for the file system. The default value is on.
sharenfs%Controls whether the file system is shared via NFS, and what options are used. A file system with a sharenfs property of off is managed the traditional way via exports(5). Otherwise, the file system is automatically shared and unshared with the "zfs share" and "zfs unshare" commands. If the property is set to on no NFS export options are used. Otherwise, NFS export options are equivalent to the contents of this property. The export options may be comma-separated. See exports(5) for a list of valid options. When the sharenfs property is changed for a dataset, the mountd(8) daemon is reloaded.
logbias%Provide a hint to ZFS about handling of synchronous requests in this dataset. If logbias is set to latency (the default), ZFS will use pool log devices (if configured) to handle the requests at low latency. If logbias is set to throughput, ZFS will not use configured pool log devices. ZFS will instead optimize synchronous operations for global pool throughput and efficient use of resources.
snapdir%Controls whether the .zfs directory is hidden or visible in the root of the file system as discussed in the "Snapshots" section. The default value is hidden.
sync%Controls the behavior of synchronous requests (e.g. fsync(2), O_DSYNC). This property accepts the following values:
volsize%For volumes, specifies the logical size of the volume. By default, creating a volume establishes a reservation of equal size. For storage pools with a version number of 9 or higher, a refreservation is set instead. Any changes to volsize are reflected in an equivalent change to the reservation (or refreservation). The volsize can only be set to a multiple of volblocksize, and cannot be zero. The reservation is kept equal to the volume's logical size to prevent unexpected behavior for consumers. Without the reservation, the volume could run out of space, resulting in undefined behavior or data corruption, depending on how the volume is used. These effects can also occur when the volume size is changed while it is in use (particularly when shrinking the size). Extreme care should be used when adjusting the volume size. Though not recommended, a "sparse volume" (also known as "thin provisioned") can be created by specifying the -s option to the "zfs create -V" command, or by changing the value of the refreservation property, or reservation property on pool version 8 or earlier after the volume has been created. A "sparse volume" is a volume where the value of refreservation is less then the size of the volume plus the space required to store its metadata. Consequently, writes to a sparse volume can fail with ENOSPC when the pool is low on space. For a sparse volume, changes to volsize are not reflected in the refreservation. A volume that is not sparse is said to be "thick provisioned". A sparse volume can become thick provisioned by setting refreservation to auto.
volmode%This property specifies how volumes should be exposed to the OS. Setting it to geom exposes volumes as geom(4) providers, providing maximal functionality. Setting it to dev exposes volumes only as cdev device in devfs. Such volumes can be accessed only as raw disk device files, i.e. they can not be partitioned, mounted, participate in RAIDs, etc, but they are faster, and in some use scenarios with untrusted consumer, such as NAS or VM storage, can be more safe. Volumes with property set to none are not exposed outside ZFS, but can be snapshoted, cloned, replicated, etc, that can be suitable for backup purposes. Value default means that volumes exposition is controlled by system-wide sysctl/tunable vfs.zfs.vol.mode, where geom, dev and none are encoded as 1, 2 and 3 respectively. The default values is geom. This property can be changed any time, but so far it is processed only during volume creation and pool import.
jailed%Controls whether the dataset is managed from a jail. See the "Jails" section for more information. The default value is off.
casesensitivity%Indicates whether the file name matching algorithm used by the file system should be case-sensitive, case-insensitive, or allow a combination of both styles of matching. The default value for the casesensitivity property is sensitive. Traditionally, UNIX and POSIX file systems have case-sensitive file names. The mixed value for the casesensitivity property indicates that the file system can support requests for both case-sensitive and case-insensitive matching behavior.
normalization%Indicates whether the file system should perform a unicode normalization of file names whenever two file names are compared, and which normalization algorithm should be used. File names are always stored unmodified, names are normalized as part of any comparison process. If this property is set to a legal value other than none, and the utf8only property was left unspecified, the utf8only property is automatically set to on. The default value of the normalization property is none. This property cannot be changed after the file system is created.
utf8only%Indicates whether the file system should reject file names that include characters that are not present in the UTF-8 character code set. If this property is explicitly set to off, the normalization property must either not be explicitly set or be set to none. The default value for the utf8only property is off. This property cannot be changed after the file system is created.
dnodesize%Specifies a compatibility mode or literal value for the size of dnodes in the file system. The default value is legacy. Setting this property to a value other than legacy requires the large_dnode pool feature to be enabled. Consider setting dnodesize to auto if the dataset uses the xattr=sa property setting and the workload makes heavy use of extended attributes. This may be applicable to SELinux-enabled systems, Lustre servers, and Samba servers, for example. Literal values are supported for cases where the optimal size is known in advance and for performance testing. Leave dnodesize set to legacy if you need to receive a send stream of this dataset on a pool that doesn't enable the large_dnode feature, or if you need to import this pool on a system that doesn't support the large_dnode feature.
