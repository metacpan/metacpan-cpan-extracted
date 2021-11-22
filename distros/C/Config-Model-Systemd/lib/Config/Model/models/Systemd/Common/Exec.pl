#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
  {
    'accept' => [
      '.*',
      {
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'Unexpected systemd parameter. Please contact cme author to update systemd model.'
      }
    ],
    'class_description' => 'Unit configuration files for services, sockets, mount points, and swap devices share a subset of
configuration options which define the execution environment of spawned processes.

This man page lists the configuration options shared by these four unit types. See
L<systemd.unit(5)> for the common
options of all unit configuration files, and
L<systemd.service(5)>,
L<systemd.socket(5)>,
L<systemd.swap(5)>, and
L<systemd.mount(5)> for more
information on the specific unit configuration files. The execution specific configuration options are configured
in the [Service], [Socket], [Mount], or [Swap] sections, depending on the unit type.

In addition, options which control resources through Linux Control Groups (cgroups) are listed in
L<systemd.resource-control(5)>.
Those options complement options listed here.

The following service exit codes are defined by the L<LSB specification|https://refspecs.linuxbase.org/LSB_5.0.0/LSB-Core-generic/LSB-Core-generic/iniscrptact.html>.



The LSB specification suggests that error codes 200 and above are reserved for implementations. Some of them are
used by the service manager to indicate problems during process invocation:


Finally, the BSD operating systems define a set of exit codes, typically defined on Linux systems too:
This configuration class was generated from systemd documentation.
by L<parse-man.pl|https://github.com/dod38fr/config-model-systemd/contrib/parse-man.pl>
',
    'copyright' => [
      '2010-2016 Lennart Poettering and others',
      '2016 Dominique Dumont'
    ],
    'element' => [
      'WorkingDirectory',
      {
        'description' => 'Takes a directory path relative to the service\'s root directory specified by
C<RootDirectory>, or the special value C<~>. Sets the working directory for
executed processes. If set to C<~>, the home directory of the user specified in
C<User> is used. If not set, defaults to the root directory when systemd is running as a
system instance and the respective user\'s home directory if run as user. If the setting is prefixed with the
C<-> character, a missing working directory is not considered fatal. If
C<RootDirectory>/C<RootImage> is not set, then
C<WorkingDirectory> is relative to the root of the system running the service manager.  Note
that setting this parameter might result in additional dependencies to be added to the unit (see
above).',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RootDirectory',
      {
        'description' => 'Takes a directory path relative to the host\'s root directory (i.e. the root of the system
running the service manager). Sets the root directory for executed processes, with the L<chroot(2)> system
call. If this is used, it must be ensured that the process binary and all its auxiliary files are available in
the chroot() jail. Note that setting this parameter might result in additional
dependencies to be added to the unit (see above).

The C<MountAPIVFS> and C<PrivateUsers> settings are particularly useful
in conjunction with C<RootDirectory>. For details, see below.

If C<RootDirectory>/C<RootImage> are used together with
C<NotifyAccess> the notification socket is automatically mounted from the host into
the root environment, to ensure the notification interface can work correctly.

Note that services using C<RootDirectory>/C<RootImage> will
not be able to log via the syslog or journal protocols to the host logging infrastructure, unless the
relevant sockets are mounted from the host, specifically:',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RootImage',
      {
        'description' => 'Takes a path to a block device node or regular file as argument. This call is similar
to C<RootDirectory> however mounts a file system hierarchy from a block device node
or loopback file instead of a directory. The device node or file system image file needs to contain a
file system without a partition table, or a file system within an MBR/MS-DOS or GPT partition table
with only a single Linux-compatible partition, or a set of file systems within a GPT partition table
that follows the L<Discoverable Partitions
Specification|https://systemd.io/DISCOVERABLE_PARTITIONS>.

When C<DevicePolicy> is set to C<closed> or
C<strict>, or set to C<auto> and C<DeviceAllow> is
set, then this setting adds C</dev/loop-control> with C<rw> mode,
C<block-loop> and C<block-blkext> with C<rwm> mode
to C<DeviceAllow>. See
L<systemd.resource-control(5)>
for the details about C<DevicePolicy> or C<DeviceAllow>. Also, see
C<PrivateDevices> below, as it may change the setting of
C<DevicePolicy>.

Units making use of C<RootImage> automatically gain an
C<After> dependency on C<systemd-udevd.service>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RootImageOptions',
      {
        'description' => 'Takes a comma-separated list of mount options that will be used on disk images specified by
C<RootImage>. Optionally a partition name can be prefixed, followed by colon, in
case the image has multiple partitions, otherwise partition name C<root> is implied.
Options for multiple partitions can be specified in a single line with space separators. Assigning an empty
string removes previous assignments. Duplicated options are ignored. For a list of valid mount options, please
refer to
L<mount(8)>.

Valid partition names follow the L<Discoverable Partitions Specification|https://systemd.io/DISCOVERABLE_PARTITIONS>:
C<root>, C<usr>, C<home>, C<srv>,
C<esp>, C<xbootldr>, C<tmp>,
C<var>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RootHash',
      {
        'description' => 'Takes a data integrity (dm-verity) root hash specified in hexadecimal, or the path to a file
containing a root hash in ASCII hexadecimal format. This option enables data integrity checks using dm-verity,
if the used image contains the appropriate integrity data (see above) or if C<RootVerity> is used.
The specified hash must match the root hash of integrity data, and is usually at least 256 bits (and hence 64
formatted hexadecimal characters) long (in case of SHA256 for example). If this option is not specified, but
the image file carries the C<user.verity.roothash> extended file attribute (see L<xattr(7)>), then the root
hash is read from it, also as formatted hexadecimal characters. If the extended file attribute is not found (or
is not supported by the underlying file system), but a file with the C<.roothash> suffix is
found next to the image file, bearing otherwise the same name (except if the image has the
C<.raw> suffix, in which case the root hash file must not have it in its name), the root hash
is read from it and automatically used, also as formatted hexadecimal characters.

If the disk image contains a separate C</usr/> partition it may also be
Verity protected, in which case the root hash may configured via an extended attribute
C<user.verity.usrhash> or a C<.usrhash> file adjacent to the disk
image. There\'s currently no option to configure the root hash for the C</usr/> file
system via the unit file directly.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RootHashSignature',
      {
        'description' => 'Takes a PKCS7 signature of the C<RootHash> option as a path to a
DER-encoded signature file, or as an ASCII base64 string encoding of a DER-encoded signature prefixed
by C<base64:>. The dm-verity volume will only be opened if the signature of the root
hash is valid and signed by a public key present in the kernel keyring. If this option is not
specified, but a file with the C<.roothash.p7s> suffix is found next to the image
file, bearing otherwise the same name (except if the image has the C<.raw> suffix,
in which case the signature file must not have it in its name), the signature is read from it and
automatically used.

If the disk image contains a separate C</usr/> partition it may also be
Verity protected, in which case the signature for the root hash may configured via a
C<.usrhash.p7s> file adjacent to the disk image. There\'s currently no option to
configure the root hash signature for the C</usr/> via the unit file
directly.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RootVerity',
      {
        'description' => 'Takes the path to a data integrity (dm-verity) file. This option enables data integrity checks
using dm-verity, if C<RootImage> is used and a root-hash is passed and if the used image itself
does not contains the integrity data. The integrity data must be matched by the root hash. If this option is not
specified, but a file with the C<.verity> suffix is found next to the image file, bearing otherwise
the same name (except if the image has the C<.raw> suffix, in which case the verity data file must
not have it in its name), the verity data is read from it and automatically used.

This option is supported only for disk images that contain a single file system, without an
enveloping partition table. Images that contain a GPT partition table should instead include both
root file system and matching Verity data in the same image, implementing the L<Discoverable Partitions Specification|https://systemd.io/DISCOVERABLE_PARTITIONS>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MountAPIVFS',
      {
        'description' => 'Takes a boolean argument. If on, a private mount namespace for the unit\'s processes is created
and the API file systems C</proc/>, C</sys/>, C</dev/> and
C</run/> (as an empty C<tmpfs>) are mounted inside of it, unless they are
already mounted. Note that this option has no effect unless used in conjunction with
C<RootDirectory>/C<RootImage> as these four mounts are
generally mounted in the host anyway, and unless the root directory is changed, the private mount namespace
will be a 1:1 copy of the host\'s, and include these four mounts. Note that the C</dev/> file
system of the host is bind mounted if this option is used without C<PrivateDevices>. To run
the service with a private, minimal version of C</dev/>, combine this option with
C<PrivateDevices>.

In order to allow propagating mounts at runtime in a safe manner, C</run/systemd/propagate>
on the host will be used to set up new mounts, and C</run/host/incoming/> in the private namespace
will be used as an intermediate step to store them before being moved to the final mount point.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'ProtectProc',
      {
        'choice' => [
          'noaccess',
          'invisible',
          'ptraceable',
          'default'
        ],
        'description' => 'Takes one of C<noaccess>, C<invisible>,
C<ptraceable> or C<default> (which it defaults to). When set, this
controls the C<hidepid=> mount option of the C<procfs> instance for
the unit that controls which directories with process metainformation
(C</proc/PID>) are visible and accessible: when set to
C<noaccess> the ability to access most of other users\' process metadata in
C</proc/> is taken away for processes of the service. When set to
C<invisible> processes owned by other users are hidden from
C</proc/>. If C<ptraceable> all processes that cannot be
ptrace()\'ed by a process are hidden to it. If C<default> no
restrictions on C</proc/> access or visibility are made. For further details see
L<The /proc
Filesystem|https://www.kernel.org/doc/html/latest/filesystems/proc.html#mount-options>. It is generally recommended to run most system services with this option set to
C<invisible>. This option is implemented via file system namespacing, and thus cannot
be used with services that shall be able to install mount points in the host file system
hierarchy. Note that the root user is unaffected by this option, so to be effective it has to be used
together with C<User> or C<DynamicUser=yes>, and also without the
C<CAP_SYS_PTRACE> capability, which also allows a process to bypass this feature. It
cannot be used for services that need to access metainformation about other users\' processes. This
option implies C<MountAPIVFS>.

If the kernel doesn\'t support per-mount point C<hidepid=> mount options this
setting remains without effect, and the unit\'s processes will be able to access and see other process
as if the option was not used.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'ProcSubset',
      {
        'choice' => [
          'all',
          'pid'
        ],
        'description' => 'Takes one of C<all> (the default) and C<pid>. If
C<pid>, all files and directories not directly associated with process management and
introspection are made invisible in the C</proc/> file system configured for the
unit\'s processes. This controls the C<subset=> mount option of the
C<procfs> instance for the unit. For further details see L<The /proc
Filesystem|https://www.kernel.org/doc/html/latest/filesystems/proc.html#mount-options>. Note that Linux exposes various kernel APIs via C</proc/>,
which are made unavailable with this setting. Since these APIs are used frequently this option is
useful only in a few, specific cases, and is not suitable for most non-trivial programs.

Much like C<ProtectProc> above, this is implemented via file system mount
namespacing, and hence the same restrictions apply: it is only available to system services, it
disables mount propagation to the host mount table, and it implies
C<MountAPIVFS>. Also, like C<ProtectProc> this setting is gracefully
disabled if the used kernel does not support the C<subset=> mount option of
C<procfs>.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'BindPaths',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Configures unit-specific bind mounts. A bind mount makes a particular file or directory
available at an additional place in the unit\'s view of the file system. Any bind mounts created with this
option are specific to the unit, and are not visible in the host\'s mount table. This option expects a
whitespace separated list of bind mount definitions. Each definition consists of a colon-separated triple of
source path, destination path and option string, where the latter two are optional. If only a source path is
specified the source and destination is taken to be the same. The option string may be either
C<rbind> or C<norbind> for configuring a recursive or non-recursive bind
mount. If the destination path is omitted, the option string must be omitted too.
Each bind mount definition may be prefixed with C<->, in which case it will be ignored
when its source path does not exist.

C<BindPaths> creates regular writable bind mounts (unless the source file system mount
is already marked read-only), while C<BindReadOnlyPaths> creates read-only bind mounts. These
settings may be used more than once, each usage appends to the unit\'s list of bind mounts. If the empty string
is assigned to either of these two options the entire list of bind mounts defined prior to this is reset. Note
that in this case both read-only and regular bind mounts are reset, regardless which of the two settings is
used.

This option is particularly useful when C<RootDirectory>/C<RootImage>
is used. In this case the source path refers to a path on the host file system, while the destination path
refers to a path below the root directory of the unit.

Note that the destination directory must exist or systemd must be able to create it.  Thus, it
is not possible to use those options for mount points nested underneath paths specified in
C<InaccessiblePaths>, or under C</home/> and other protected
directories if C<ProtectHome=yes> is
specified. C<TemporaryFileSystem> with C<:ro> or
C<ProtectHome=tmpfs> should be used instead.',
        'type' => 'list'
      },
      'BindReadOnlyPaths',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Configures unit-specific bind mounts. A bind mount makes a particular file or directory
available at an additional place in the unit\'s view of the file system. Any bind mounts created with this
option are specific to the unit, and are not visible in the host\'s mount table. This option expects a
whitespace separated list of bind mount definitions. Each definition consists of a colon-separated triple of
source path, destination path and option string, where the latter two are optional. If only a source path is
specified the source and destination is taken to be the same. The option string may be either
C<rbind> or C<norbind> for configuring a recursive or non-recursive bind
mount. If the destination path is omitted, the option string must be omitted too.
Each bind mount definition may be prefixed with C<->, in which case it will be ignored
when its source path does not exist.

C<BindPaths> creates regular writable bind mounts (unless the source file system mount
is already marked read-only), while C<BindReadOnlyPaths> creates read-only bind mounts. These
settings may be used more than once, each usage appends to the unit\'s list of bind mounts. If the empty string
is assigned to either of these two options the entire list of bind mounts defined prior to this is reset. Note
that in this case both read-only and regular bind mounts are reset, regardless which of the two settings is
used.

This option is particularly useful when C<RootDirectory>/C<RootImage>
is used. In this case the source path refers to a path on the host file system, while the destination path
refers to a path below the root directory of the unit.

Note that the destination directory must exist or systemd must be able to create it.  Thus, it
is not possible to use those options for mount points nested underneath paths specified in
C<InaccessiblePaths>, or under C</home/> and other protected
directories if C<ProtectHome=yes> is
specified. C<TemporaryFileSystem> with C<:ro> or
C<ProtectHome=tmpfs> should be used instead.',
        'type' => 'list'
      },
      'MountImages',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'This setting is similar to C<RootImage> in that it mounts a file
system hierarchy from a block device node or loopback file, but the destination directory can be
specified as well as mount options. This option expects a whitespace separated list of mount
definitions. Each definition consists of a colon-separated tuple of source path and destination
definitions, optionally followed by another colon and a list of mount options.

Mount options may be defined as a single comma-separated list of options, in which case they
will be implicitly applied to the root partition on the image, or a series of colon-separated tuples
of partition name and mount options. Valid partition names and mount options are the same as for
C<RootImageOptions> setting described above.

Each mount definition may be prefixed with C<->, in which case it will be
ignored when its source path does not exist. The source argument is a path to a block device node or
regular file. If source or destination contain a C<:>, it needs to be escaped as
C<\\:>. The device node or file system image file needs to follow the same rules as
specified for C<RootImage>. Any mounts created with this option are specific to the
unit, and are not visible in the host\'s mount table.

These settings may be used more than once, each usage appends to the unit\'s list of mount
paths. If the empty string is assigned, the entire list of mount paths defined prior to this is
reset.

Note that the destination directory must exist or systemd must be able to create it.  Thus, it
is not possible to use those options for mount points nested underneath paths specified in
C<InaccessiblePaths>, or under C</home/> and other protected
directories if C<ProtectHome=yes> is specified.

When C<DevicePolicy> is set to C<closed> or
C<strict>, or set to C<auto> and C<DeviceAllow> is
set, then this setting adds C</dev/loop-control> with C<rw> mode,
C<block-loop> and C<block-blkext> with C<rwm> mode
to C<DeviceAllow>. See
L<systemd.resource-control(5)>
for the details about C<DevicePolicy> or C<DeviceAllow>. Also, see
C<PrivateDevices> below, as it may change the setting of
C<DevicePolicy>.',
        'type' => 'list'
      },
      'ExtensionImages',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'This setting is similar to C<MountImages> in that it mounts a file
system hierarchy from a block device node or loopback file, but instead of providing a destination
path, an overlay will be set up. This option expects a whitespace separated list of mount
definitions. Each definition consists of a source path, optionally followed by a colon and a list of
mount options.

A read-only OverlayFS will be set up on top of C</usr/> and
C</opt/> hierarchies. The order in which the images are listed will determine the
order in which the overlay is laid down: images specified first to last will result in overlayfs
layers bottom to top.

Mount options may be defined as a single comma-separated list of options, in which case they
will be implicitly applied to the root partition on the image, or a series of colon-separated tuples
of partition name and mount options. Valid partition names and mount options are the same as for
C<RootImageOptions> setting described above.

Each mount definition may be prefixed with C<->, in which case it will be
ignored when its source path does not exist. The source argument is a path to a block device node or
regular file. If the source path contains a C<:>, it needs to be escaped as
C<\\:>. The device node or file system image file needs to follow the same rules as
specified for C<RootImage>. Any mounts created with this option are specific to the
unit, and are not visible in the host\'s mount table.

These settings may be used more than once, each usage appends to the unit\'s list of image
paths. If the empty string is assigned, the entire list of mount paths defined prior to this is
reset.

When C<DevicePolicy> is set to C<closed> or
C<strict>, or set to C<auto> and C<DeviceAllow> is
set, then this setting adds C</dev/loop-control> with C<rw> mode,
C<block-loop> and C<block-blkext> with C<rwm> mode
to C<DeviceAllow>. See
L<systemd.resource-control(5)>
for the details about C<DevicePolicy> or C<DeviceAllow>. Also, see
C<PrivateDevices> below, as it may change the setting of
C<DevicePolicy>.',
        'type' => 'list'
      },
      'User',
      {
        'description' => "Set the UNIX user or group that the processes are executed as, respectively. Takes a single
user or group name, or a numeric ID as argument. For system services (services run by the system service
manager, i.e. managed by PID 1) and for user services of the root user (services managed by root's instance of
systemd --user), the default is C<root>, but C<User> may be
used to specify a different user. For user services of any other user, switching user identity is not
permitted, hence the only valid setting is the same user the user's service manager is running as. If no group
is set, the default group of the user is used. This setting does not affect commands whose command line is
prefixed with C<+>.

Note that this enforces only weak restrictions on the user/group name syntax, but will generate
warnings in many cases where user/group names do not adhere to the following rules: the specified
name should consist only of the characters a-z, A-Z, 0-9, C<_> and
C<->, except for the first character which must be one of a-z, A-Z and
C<_> (i.e. digits and C<-> are not permitted as first character). The
user/group name must have at least one character, and at most 31. These restrictions are made in
order to avoid ambiguities and to ensure user/group names and unit files remain portable among Linux
systems. For further details on the names accepted and the names warned about see L<User/Group Name Syntax|https://systemd.io/USER_NAMES>.

When used in conjunction with C<DynamicUser> the user/group name specified is
dynamically allocated at the time the service is started, and released at the time the service is
stopped \x{2014} unless it is already allocated statically (see below). If C<DynamicUser>
is not used the specified user and group must have been created statically in the user database no
later than the moment the service is started, for example using the
L<sysusers.d(5)>
facility, which is applied at boot or package install time. If the user does not exist by then
program invocation will fail.

If the C<User> setting is used the supplementary group list is initialized
from the specified user's default group list, as defined in the system's user and group
database. Additional groups may be configured through the C<SupplementaryGroups>
setting (see below).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Group',
      {
        'description' => "Set the UNIX user or group that the processes are executed as, respectively. Takes a single
user or group name, or a numeric ID as argument. For system services (services run by the system service
manager, i.e. managed by PID 1) and for user services of the root user (services managed by root's instance of
systemd --user), the default is C<root>, but C<User> may be
used to specify a different user. For user services of any other user, switching user identity is not
permitted, hence the only valid setting is the same user the user's service manager is running as. If no group
is set, the default group of the user is used. This setting does not affect commands whose command line is
prefixed with C<+>.

Note that this enforces only weak restrictions on the user/group name syntax, but will generate
warnings in many cases where user/group names do not adhere to the following rules: the specified
name should consist only of the characters a-z, A-Z, 0-9, C<_> and
C<->, except for the first character which must be one of a-z, A-Z and
C<_> (i.e. digits and C<-> are not permitted as first character). The
user/group name must have at least one character, and at most 31. These restrictions are made in
order to avoid ambiguities and to ensure user/group names and unit files remain portable among Linux
systems. For further details on the names accepted and the names warned about see L<User/Group Name Syntax|https://systemd.io/USER_NAMES>.

When used in conjunction with C<DynamicUser> the user/group name specified is
dynamically allocated at the time the service is started, and released at the time the service is
stopped \x{2014} unless it is already allocated statically (see below). If C<DynamicUser>
is not used the specified user and group must have been created statically in the user database no
later than the moment the service is started, for example using the
L<sysusers.d(5)>
facility, which is applied at boot or package install time. If the user does not exist by then
program invocation will fail.

If the C<User> setting is used the supplementary group list is initialized
from the specified user's default group list, as defined in the system's user and group
database. Additional groups may be configured through the C<SupplementaryGroups>
setting (see below).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'DynamicUser',
      {
        'description' => "Takes a boolean parameter. If set, a UNIX user and group pair is allocated
dynamically when the unit is started, and released as soon as it is stopped. The user and group will
not be added to C</etc/passwd> or C</etc/group>, but are managed
transiently during runtime. The
L<nss-systemd(8)> glibc
NSS module provides integration of these dynamic users/groups into the system's user and group
databases. The user and group name to use may be configured via C<User> and
C<Group> (see above). If these options are not used and dynamic user/group
allocation is enabled for a unit, the name of the dynamic user/group is implicitly derived from the
unit name. If the unit name without the type suffix qualifies as valid user name it is used directly,
otherwise a name incorporating a hash of it is used. If a statically allocated user or group of the
configured name already exists, it is used and no dynamic user/group is allocated. Note that if
C<User> is specified and the static group with the name exists, then it is required
that the static user with the name already exists. Similarly, if C<Group> is
specified and the static user with the name exists, then it is required that the static group with
the name already exists. Dynamic users/groups are allocated from the UID/GID range 61184\x{2026}65519. It is
recommended to avoid this range for regular system or login users.  At any point in time each UID/GID
from this range is only assigned to zero or one dynamically allocated users/groups in use. However,
UID/GIDs are recycled after a unit is terminated. Care should be taken that any processes running as
part of a unit for which dynamic users/groups are enabled do not leave files or directories owned by
these users/groups around, as a different unit might get the same UID/GID assigned later on, and thus
gain access to these files or directories. If C<DynamicUser> is enabled,
C<RemoveIPC> and C<PrivateTmp> are implied (and cannot be turned
off). This ensures that the lifetime of IPC objects and temporary files created by the executed
processes is bound to the runtime of the service, and hence the lifetime of the dynamic
user/group. Since C</tmp/> and C</var/tmp/> are usually the only
world-writable directories on a system this ensures that a unit making use of dynamic user/group
allocation cannot leave files around after unit termination. Furthermore
C<NoNewPrivileges> and C<RestrictSUIDSGID> are implicitly enabled
(and cannot be disabled), to ensure that processes invoked cannot take benefit or create SUID/SGID
files or directories. Moreover C<ProtectSystem=strict> and
C<ProtectHome=read-only> are implied, thus prohibiting the service to write to
arbitrary file system locations. In order to allow the service to write to certain directories, they
have to be allow-listed using C<ReadWritePaths>, but care must be taken so that
UID/GID recycling doesn't create security issues involving files created by the service. Use
C<RuntimeDirectory> (see below) in order to assign a writable runtime directory to a
service, owned by the dynamic user/group and removed automatically when the unit is terminated. Use
C<StateDirectory>, C<CacheDirectory> and
C<LogsDirectory> in order to assign a set of writable directories for specific
purposes to the service in a way that they are protected from vulnerabilities due to UID reuse (see
below). If this option is enabled, care should be taken that the unit's processes do not get access
to directories outside of these explicitly configured and managed ones. Specifically, do not use
C<BindPaths> and be careful with C<AF_UNIX> file descriptor
passing for directory file descriptors, as this would permit processes to create files or directories
owned by the dynamic user/group that are not subject to the lifecycle and access guarantees of the
service. Defaults to off.",
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'SupplementaryGroups',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Sets the supplementary Unix groups the processes are executed as. This takes a space-separated
list of group names or IDs. This option may be specified more than once, in which case all listed groups are
set as supplementary groups. When the empty string is assigned, the list of supplementary groups is reset, and
all assignments prior to this one will have no effect. In any way, this option does not override, but extends
the list of supplementary groups configured in the system group database for the user. This does not affect
commands prefixed with C<+>.',
        'type' => 'list'
      },
      'PAMName',
      {
        'description' => 'Sets the PAM service name to set up a session as. If set, the executed process will be
registered as a PAM session under the specified service name. This is only useful in conjunction with the
C<User> setting, and is otherwise ignored. If not set, no PAM session will be opened for the
executed processes. See L<pam(8)> for
details.

Note that for each unit making use of this option a PAM session handler process will be maintained as
part of the unit and stays around as long as the unit is active, to ensure that appropriate actions can be
taken when the unit and hence the PAM session terminates. This process is named C<(sd-pam)> and
is an immediate child process of the unit\'s main process.

Note that when this option is used for a unit it is very likely (depending on PAM configuration) that the
main unit process will be migrated to its own session scope unit when it is activated. This process will hence
be associated with two units: the unit it was originally started from (and for which
C<PAMName> was configured), and the session scope unit. Any child processes of that process
will however be associated with the session scope unit only. This has implications when used in combination
with C<NotifyAccess>C<all>, as these child processes will not be able to affect
changes in the original unit through notification messages. These messages will be considered belonging to the
session scope unit and not the original unit. It is hence not recommended to use C<PAMName> in
combination with C<NotifyAccess>C<all>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CapabilityBoundingSet',
      {
        'description' => 'Controls which capabilities to include in the capability bounding set for the
executed process. See L<capabilities(7)>
for details. Takes a whitespace-separated list of capability names,
e.g. C<CAP_SYS_ADMIN>, C<CAP_DAC_OVERRIDE>,
C<CAP_SYS_PTRACE>. Capabilities listed will be included in the bounding set, all
others are removed. If the list of capabilities is prefixed with C<~>, all but the
listed capabilities will be included, the effect of the assignment inverted. Note that this option
also affects the respective capabilities in the effective, permitted and inheritable capability
sets. If this option is not used, the capability bounding set is not modified on process execution,
hence no limits on the capabilities of the process are enforced. This option may appear more than
once, in which case the bounding sets are merged by C<OR>, or by
C<AND> if the lines are prefixed with C<~> (see below). If the
empty string is assigned to this option, the bounding set is reset to the empty capability set, and
all prior settings have no effect.  If set to C<~> (without any further argument),
the bounding set is reset to the full set of available capabilities, also undoing any previous
settings. This does not affect commands prefixed with C<+>.

Use
L<systemd-analyze(1)>\'s
capability command to retrieve a list of capabilities defined on the local
system.

Example: if a unit has the following,

    CapabilityBoundingSet=CAP_A CAP_B
    CapabilityBoundingSet=CAP_B CAP_C

then C<CAP_A>, C<CAP_B>, and
C<CAP_C> are set.  If the second line is prefixed with
C<~>, e.g.,

    CapabilityBoundingSet=CAP_A CAP_B
    CapabilityBoundingSet=~CAP_B CAP_C

then, only C<CAP_A> is set.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AmbientCapabilities',
      {
        'description' => 'Controls which capabilities to include in the ambient capability set for the executed
process. Takes a whitespace-separated list of capability names, e.g. C<CAP_SYS_ADMIN>,
C<CAP_DAC_OVERRIDE>, C<CAP_SYS_PTRACE>. This option may appear more than
once in which case the ambient capability sets are merged (see the above examples in
C<CapabilityBoundingSet>). If the list of capabilities is prefixed with C<~>,
all but the listed capabilities will be included, the effect of the assignment inverted. If the empty string is
assigned to this option, the ambient capability set is reset to the empty capability set, and all prior
settings have no effect.  If set to C<~> (without any further argument), the ambient capability
set is reset to the full set of available capabilities, also undoing any previous settings. Note that adding
capabilities to ambient capability set adds them to the process\'s inherited capability set.

Ambient capability sets are useful if you want to execute a process as a non-privileged user but still want to
give it some capabilities.  Note that in this case option C<keep-caps> is automatically added
to C<SecureBits> to retain the capabilities over the user
change. C<AmbientCapabilities> does not affect commands prefixed with
C<+>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'NoNewPrivileges',
      {
        'description' => 'Takes a boolean argument. If true, ensures that the service process and all its
children can never gain new privileges through execve() (e.g. via setuid or
setgid bits, or filesystem capabilities). This is the simplest and most effective way to ensure that
a process and its children can never elevate privileges again. Defaults to false, but certain
settings override this and ignore the value of this setting.  This is the case when
C<DynamicUser>,
C<LockPersonality>,
C<MemoryDenyWriteExecute>,
C<PrivateDevices>,
C<ProtectClock>,
C<ProtectHostname>,
C<ProtectKernelLogs>,
C<ProtectKernelModules>,
C<ProtectKernelTunables>,
C<RestrictAddressFamilies>,
C<RestrictNamespaces>,
C<RestrictRealtime>,
C<RestrictSUIDSGID>,
C<SystemCallArchitectures>,
C<SystemCallFilter>, or
C<SystemCallLog> are specified. Note that even if this setting is overridden
by them, systemctl show shows the original value of this setting. In case the
service will be run in a new mount namespace anyway and SELinux is disabled, all file systems
are mounted with C<MS_NOSUID> flag. Also see
L<No New
Privileges Flag|https://www.kernel.org/doc/html/latest/userspace-api/no_new_privs.html>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'SecureBits',
      {
        'description' => 'Controls the secure bits set for the executed process. Takes a space-separated combination of
options from the following list: C<keep-caps>, C<keep-caps-locked>,
C<no-setuid-fixup>, C<no-setuid-fixup-locked>, C<noroot>, and
C<noroot-locked>.  This option may appear more than once, in which case the secure bits are
ORed. If the empty string is assigned to this option, the bits are reset to 0. This does not affect commands
prefixed with C<+>.  See L<capabilities(7)> for
details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SELinuxContext',
      {
        'description' => 'Set the SELinux security context of the executed process. If set, this will override the
automated domain transition. However, the policy still needs to authorize the transition. This directive is
ignored if SELinux is disabled. If prefixed by C<->, all errors will be ignored. This does not
affect commands prefixed with C<+>.  See L<setexeccon(3)> for
details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AppArmorProfile',
      {
        'description' => 'Takes a profile name as argument. The process executed by the unit will switch to
this profile when started. Profiles must already be loaded in the kernel, or the unit will fail. If
prefixed by C<->, all errors will be ignored. This setting has no effect if AppArmor
is not enabled. This setting does not affect commands prefixed with C<+>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SmackProcessLabel',
      {
        'description' => 'Takes a C<SMACK64> security label as argument. The process executed by the unit
will be started under this label and SMACK will decide whether the process is allowed to run or not, based on
it. The process will continue to run under the label specified here unless the executable has its own
C<SMACK64EXEC> label, in which case the process will transition to run under that label. When not
specified, the label that systemd is running under is used. This directive is ignored if SMACK is
disabled.

The value may be prefixed by C<->, in which case all errors will be ignored. An empty
value may be specified to unset previous assignments. This does not affect commands prefixed with
C<+>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitCPU',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitFSIZE',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitDATA',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitSTACK',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitCORE',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitRSS',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitNOFILE',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitAS',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitNPROC',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitMEMLOCK',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitLOCKS',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitSIGPENDING',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitMSGQUEUE',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitNICE',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitRTPRIO',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitRTTIME',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for
details on the resource limit concept. Resource limits may be specified in two formats: either as
single value to set a specific soft and hard limit to the same value, or as colon-separated pair
C<soft:hard> to set both limits individually (e.g. C<LimitAS=4G:16G>).
Use the string C<infinity> to configure no limit on a specific resource. The
multiplicative suffixes K, M, G, T, P and E (to the base 1024) may be used for resource limits
measured in bytes (e.g. C<LimitAS=16G>). For the limits referring to time values, the
usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of
seconds is implied, while for C<LimitRTTIME> the default unit of microseconds is
implied. Also, note that the effective granularity of the limits might influence their
enforcement. For example, time limits specified for C<LimitCPU> will be rounded up
implicitly to multiples of 1s. For C<LimitNICE> the value may be specified in two
syntaxes: if prefixed with C<+> or C<->, the value is understood as
regular Linux nice value in the range -20\x{2026}19. If not prefixed like this the value is understood as
raw resource limit parameter in the range 0\x{2026}40 (with 0 being equivalent to 1).

Note that most process resource limits configured with these options are per-process, and
processes may fork in order to acquire a new set of resources that are accounted independently of the
original process, and may thus escape limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it is advisable to prefer the resource
controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a whole, may be altered dynamically at
runtime, and are generally more expressive. For example, C<MemoryMax> is a more
powerful (and working) replacement for C<LimitRSS>.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see below).

For system units these resource limits may be chosen freely. When these settings are configured
in a user service (i.e. a service run by the per-user instance of the service manager) they cannot be
used to raise the limits above those set for the user manager itself when it was first invoked, as
the user's service manager generally lacks the privileges to do so. In user context these
configuration options are hence only useful to lower the limits passed in or to raise the soft limit
to the maximum of the hard limit as configured for the user. To raise the user's limits further, the
available configuration mechanisms differ between operating systems, but typically require
privileges. In most cases it is possible to configure higher per-user resource limits via PAM or by
setting limits on the system service encapsulating the user's service manager, i.e. the user's
instance of C<user\@.service>. After making such changes, make sure to restart the
user's service manager.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UMask',
      {
        'description' => "Controls the file mode creation mask. Takes an access mode in octal notation. See
L<umask(2)> for
details. Defaults to 0022 for system units. For user units the default value is inherited from the
per-user service manager (whose default is in turn inherited from the system service manager, and
thus typically also is 0022 \x{2014} unless overridden by a PAM module). In order to change the per-user mask
for all user services, consider setting the C<UMask> setting of the user's
C<user\@.service> system service instance. The per-user umask may also be set via
the C<umask> field of a user's L<JSON User
Record|https://systemd.io/USER_RECORD> (for users managed by
L<systemd-homed.service(8)>
this field may be controlled via homectl --umask=). It may also be set via a PAM
module, such as L<pam_umask(8)>.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CoredumpFilter',
      {
        'description' => 'Controls which types of memory mappings will be saved if the process dumps core
(using the C</proc/pid/coredump_filter> file). Takes a
whitespace-separated combination of mapping type names or numbers (with the default base 16). Mapping
type names are C<private-anonymous>, C<shared-anonymous>,
C<private-file-backed>, C<shared-file-backed>,
C<elf-headers>, C<private-huge>,
C<shared-huge>, C<private-dax>, C<shared-dax>,
and the special values C<all> (all types) and C<default> (the
kernel default of C<C<private-anonymous>C<shared-anonymous> C<elf-headers>C<private-huge>>). See
L<core(5)>
for the meaning of the mapping types. When specified multiple times, all specified masks are
ORed. When not set, or if the empty value is assigned, the inherited value is not changed.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'KeyringMode',
      {
        'choice' => [
          'inherit',
          'private',
          'shared'
        ],
        'description' => 'Controls how the kernel session keyring is set up for the service (see L<session-keyring(7)> for
details on the session keyring). Takes one of C<inherit>, C<private>,
C<shared>. If set to C<inherit> no special keyring setup is done, and the kernel\'s
default behaviour is applied. If C<private> is used a new session keyring is allocated when a
service process is invoked, and it is not linked up with any user keyring. This is the recommended setting for
system services, as this ensures that multiple services running under the same system user ID (in particular
the root user) do not share their key material among each other. If C<shared> is used a new
session keyring is allocated as for C<private>, but the user keyring of the user configured with
C<User> is linked into it, so that keys assigned to the user may be requested by the unit\'s
processes. In this modes multiple units running processes under the same user ID may share key material. Unless
C<inherit> is selected the unique invocation ID for the unit (see below) is added as a protected
key by the name C<invocation_id> to the newly created session keyring. Defaults to
C<private> for services of the system service manager and to C<inherit> for
non-service units and for services of the user service manager.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'OOMScoreAdjust',
      {
        'description' => 'Sets the adjustment value for the Linux kernel\'s Out-Of-Memory (OOM) killer score for
executed processes. Takes an integer between -1000 (to disable OOM killing of processes of this unit)
and 1000 (to make killing of processes of this unit under memory pressure very likely). See L<proc.txt|https://www.kernel.org/doc/Documentation/filesystems/proc.txt> for details. If
not specified defaults to the OOM score adjustment level of the service manager itself, which is
normally at 0.

Use the C<OOMPolicy> setting of service units to configure how the service
manager shall react to the kernel OOM killer terminating a process of the service.  See
L<systemd.service(5)>
for details.',
        'max' => '1000',
        'min' => '-1000',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'TimerSlackNSec',
      {
        'description' => 'Sets the timer slack in nanoseconds for the executed processes. The timer slack controls the
accuracy of wake-ups triggered by timers. See
L<prctl(2)> for more
information. Note that in contrast to most other time span definitions this parameter takes an integer value in
nano-seconds if no unit is specified. The usual time units are understood too.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Personality',
      {
        'choice' => [
          'x86',
          'x86-64',
          'ppc',
          'ppc-le',
          'ppc64',
          'ppc64-le',
          's390',
          's390x'
        ],
        'description' => 'Controls which kernel architecture L<uname(2)> shall report,
when invoked by unit processes. Takes one of the architecture identifiers C<x86>,
C<x86-64>, C<ppc>, C<ppc-le>, C<ppc64>,
C<ppc64-le>, C<s390> or C<s390x>. Which personality
architectures are supported depends on the system architecture. Usually the 64bit versions of the various
system architectures support their immediate 32bit personality architecture counterpart, but no others. For
example, C<x86-64> systems support the C<x86-64> and
C<x86> personalities but no others. The personality feature is useful when running 32-bit
services on a 64-bit host system. If not specified, the personality is left unmodified and thus reflects the
personality of the host system\'s kernel.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'IgnoreSIGPIPE',
      {
        'description' => 'Takes a boolean argument. If true, causes C<SIGPIPE> to be ignored in the
executed process. Defaults to true because C<SIGPIPE> generally is useful only in shell
pipelines.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Nice',
      {
        'description' => 'Sets the default nice level (scheduling priority) for executed processes. Takes an
integer between -20 (highest priority) and 19 (lowest priority). In case of resource contention,
smaller values mean more resources will be made available to the unit\'s processes, larger values mean
less resources will be made available. See
L<setpriority(2)> for
details.',
        'max' => '19',
        'min' => '-20',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'CPUSchedulingPolicy',
      {
        'choice' => [
          'other',
          'batch',
          'idle',
          'fifo',
          'rr'
        ],
        'description' => 'Sets the CPU scheduling policy for executed processes. Takes one of C<other>,
C<batch>, C<idle>, C<fifo> or C<rr>. See
L<sched_setscheduler(2)> for
details.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'CPUSchedulingPriority',
      {
        'description' => 'Sets the CPU scheduling priority for executed processes. The available priority range
depends on the selected CPU scheduling policy (see above). For real-time scheduling policies an
integer between 1 (lowest priority) and 99 (highest priority) can be used. In case of CPU resource
contention, smaller values mean less CPU time is made available to the service, larger values mean
more. See L<sched_setscheduler(2)>
for details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CPUSchedulingResetOnFork',
      {
        'description' => 'Takes a boolean argument. If true, elevated CPU scheduling priorities and policies
will be reset when the executed processes call
L<fork(2)>,
and can hence not leak into child processes. See
L<sched_setscheduler(2)>
for details. Defaults to false.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'CPUAffinity',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Controls the CPU affinity of the executed processes. Takes a list of CPU indices or ranges
separated by either whitespace or commas. Alternatively, takes a special "numa" value in which case systemd
automatically derives allowed CPU range based on the value of C<NUMAMask> option. CPU ranges
are specified by the lower and upper CPU indices separated by a dash. This option may be specified more than
once, in which case the specified CPU affinity masks are merged. If the empty string is assigned, the mask
is reset, all assignments prior to this will have no effect. See
L<sched_setaffinity(2)> for
details.',
        'type' => 'list'
      },
      'NUMAPolicy',
      {
        'description' => 'Controls the NUMA memory policy of the executed processes. Takes a policy type, one of:
C<default>, C<preferred>, C<bind>, C<interleave> and
C<local>. A list of NUMA nodes that should be associated with the policy must be specified
in C<NUMAMask>. For more details on each policy please see,
L<set_mempolicy(2)>. For overall
overview of NUMA support in Linux see,
L<numa(7)>.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'NUMAMask',
      {
        'description' => 'Controls the NUMA node list which will be applied alongside with selected NUMA policy.
Takes a list of NUMA nodes and has the same syntax as a list of CPUs for C<CPUAffinity>
option or special "all" value which will include all available NUMA nodes in the mask. Note that the list
of NUMA nodes is not required for C<default> and C<local>
policies and for C<preferred> policy we expect a single NUMA node.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IOSchedulingClass',
      {
        'choice' => [
          '0',
          '1',
          '2',
          '3',
          'none',
          'realtime',
          'best-effort',
          'idle'
        ],
        'description' => 'Sets the I/O scheduling class for executed processes. Takes an integer between 0 and 3 or one
of the strings C<none>, C<realtime>, C<best-effort> or
C<idle>. If the empty string is assigned to this option, all prior assignments to both
C<IOSchedulingClass> and C<IOSchedulingPriority> have no effect. See
L<ioprio_set(2)> for
details.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'IOSchedulingPriority',
      {
        'description' => 'Sets the I/O scheduling priority for executed processes. Takes an integer between 0
(highest priority) and 7 (lowest priority). In case of I/O contention, smaller values mean more I/O
bandwidth is made available to the unit\'s processes, larger values mean less bandwidth. The available
priorities depend on the selected I/O scheduling class (see above). If the empty string is assigned
to this option, all prior assignments to both C<IOSchedulingClass> and
C<IOSchedulingPriority> have no effect.  See
L<ioprio_set(2)> for
details.',
        'max' => '7',
        'min' => '0',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'ProtectSystem',
      {
        'choice' => [
          'no',
          'yes',
          'full',
          'strict'
        ],
        'description' => 'Takes a boolean argument or the special values C<full> or
C<strict>. If true, mounts the C</usr/> and the boot loader
directories (C</boot> and C</efi>) read-only for processes
invoked by this unit. If set to C<full>, the C</etc/> directory is
mounted read-only, too. If set to C<strict> the entire file system hierarchy is
mounted read-only, except for the API file system subtrees C</dev/>,
C</proc/> and C</sys/> (protect these directories using
C<PrivateDevices>, C<ProtectKernelTunables>,
C<ProtectControlGroups>). This setting ensures that any modification of the vendor-supplied
operating system (and optionally its configuration, and local mounts) is prohibited for the service.  It is
recommended to enable this setting for all long-running services, unless they are involved with system updates
or need to modify the operating system in other ways. If this option is used,
C<ReadWritePaths> may be used to exclude specific directories from being made read-only. This
setting is implied if C<DynamicUser> is set. This setting cannot ensure protection in all
cases. In general it has the same limitations as C<ReadOnlyPaths>, see below. Defaults to
off.',
        'replace' => {
          '0' => 'no',
          '1' => 'yes',
          'false' => 'no',
          'true' => 'yes'
        },
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'ProtectHome',
      {
        'choice' => [
          'no',
          'yes',
          'read-only',
          'tmpfs'
        ],
        'description' => 'Takes a boolean argument or the special values C<read-only> or
C<tmpfs>. If true, the directories C</home/>,
C</root>, and C</run/user> are made inaccessible and empty for
processes invoked by this unit. If set to C<read-only>, the three directories are
made read-only instead. If set to C<tmpfs>, temporary file systems are mounted on the
three directories in read-only mode. The value C<tmpfs> is useful to hide home
directories not relevant to the processes invoked by the unit, while still allowing necessary
directories to be made visible when listed in C<BindPaths> or
C<BindReadOnlyPaths>.

Setting this to C<yes> is mostly equivalent to set the three directories in
C<InaccessiblePaths>. Similarly, C<read-only> is mostly equivalent to
C<ReadOnlyPaths>, and C<tmpfs> is mostly equivalent to
C<TemporaryFileSystem> with C<:ro>.

It is recommended to enable this setting for all long-running services (in particular
network-facing ones), to ensure they cannot get access to private user data, unless the services
actually require access to the user\'s private data. This setting is implied if
C<DynamicUser> is set. This setting cannot ensure protection in all cases. In
general it has the same limitations as C<ReadOnlyPaths>, see below.',
        'replace' => {
          '0' => 'no',
          '1' => 'yes',
          'false' => 'no',
          'true' => 'yes'
        },
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'RuntimeDirectory',
      {
        'description' => "These options take a whitespace-separated list of directory names. The specified
directory names must be relative, and may not include C<..>. If set, when the unit is
started, one or more directories by the specified names will be created (including their parents)
below the locations defined in the following table. Also, the corresponding environment variable will
be defined with the full paths of the directories. If multiple directories are set, then in the
environment variable the paths are concatenated with colon (C<:>).

In case of C<RuntimeDirectory> the innermost subdirectories are removed when
the unit is stopped. It is possible to preserve the specified directories in this case if
C<RuntimeDirectoryPreserve> is configured to C<restart> or
C<yes> (see below). The directories specified with C<StateDirectory>,
C<CacheDirectory>, C<LogsDirectory>,
C<ConfigurationDirectory> are not removed when the unit is stopped.

Except in case of C<ConfigurationDirectory>, the innermost specified directories will be
owned by the user and group specified in C<User> and C<Group>. If the
specified directories already exist and their owning user or group do not match the configured ones, all files
and directories below the specified directories as well as the directories themselves will have their file
ownership recursively changed to match what is configured. As an optimization, if the specified directories are
already owned by the right user and group, files and directories below of them are left as-is, even if they do
not match what is requested. The innermost specified directories will have their access mode adjusted to the
what is specified in C<RuntimeDirectoryMode>, C<StateDirectoryMode>,
C<CacheDirectoryMode>, C<LogsDirectoryMode> and
C<ConfigurationDirectoryMode>.

These options imply C<BindPaths> for the specified paths. When combined with
C<RootDirectory> or C<RootImage> these paths always reside on the host and
are mounted from there into the unit's file system namespace.

If C<DynamicUser> is used, the logic for C<CacheDirectory>,
C<LogsDirectory> and C<StateDirectory> is slightly altered: the directories are created below
C</var/cache/private>, C</var/log/private> and C</var/lib/private>,
respectively, which are host directories made inaccessible to
unprivileged users, which ensures that access to these directories cannot be gained through dynamic
user ID recycling. Symbolic links are created to hide this difference in behaviour. Both from
perspective of the host and from inside the unit, the relevant directories hence always appear
directly below C</var/cache>, C</var/log> and
C</var/lib>.

Use C<RuntimeDirectory> to manage one or more runtime directories for the unit and bind
their lifetime to the daemon runtime. This is particularly useful for unprivileged daemons that cannot create
runtime directories in C</run/> due to lack of privileges, and to make sure the runtime
directory is cleaned up automatically after use. For runtime directories that require more complex or different
configuration or lifetime guarantees, please consider using
L<tmpfiles.d(5)>.

The directories defined by these options are always created under the standard paths used by systemd
(C</var/>, C</run/>, C</etc/>, \x{2026}). If the service needs
directories in a different location, a different mechanism has to be used to create them.

L<tmpfiles.d(5)> provides
functionality that overlaps with these options. Using these options is recommended, because the lifetime of
the directories is tied directly to the lifetime of the unit, and it is not necessary to ensure that the
C<tmpfiles.d> configuration is executed before the unit is started.

To remove any of the directories created by these settings, use the systemctl clean
\x{2026} command on the relevant units, see
L<systemctl(1)> for
details.

Example: if a system service unit has the following,

    RuntimeDirectory=foo/bar baz

the service manager creates C</run/foo> (if it does not exist),
C</run/foo/bar>, and C</run/baz>. The
directories C</run/foo/bar> and
C</run/baz> except C</run/foo> are
owned by the user and group specified in C<User> and C<Group>, and removed
when the service is stopped.

Example: if a system service unit has the following,

    RuntimeDirectory=foo/bar
    StateDirectory=aaa/bbb ccc

then the environment variable C<RUNTIME_DIRECTORY> is set with C</run/foo/bar>, and
C<STATE_DIRECTORY> is set with C</var/lib/aaa/bbb:/var/lib/ccc>.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StateDirectory',
      {
        'description' => "These options take a whitespace-separated list of directory names. The specified
directory names must be relative, and may not include C<..>. If set, when the unit is
started, one or more directories by the specified names will be created (including their parents)
below the locations defined in the following table. Also, the corresponding environment variable will
be defined with the full paths of the directories. If multiple directories are set, then in the
environment variable the paths are concatenated with colon (C<:>).

In case of C<RuntimeDirectory> the innermost subdirectories are removed when
the unit is stopped. It is possible to preserve the specified directories in this case if
C<RuntimeDirectoryPreserve> is configured to C<restart> or
C<yes> (see below). The directories specified with C<StateDirectory>,
C<CacheDirectory>, C<LogsDirectory>,
C<ConfigurationDirectory> are not removed when the unit is stopped.

Except in case of C<ConfigurationDirectory>, the innermost specified directories will be
owned by the user and group specified in C<User> and C<Group>. If the
specified directories already exist and their owning user or group do not match the configured ones, all files
and directories below the specified directories as well as the directories themselves will have their file
ownership recursively changed to match what is configured. As an optimization, if the specified directories are
already owned by the right user and group, files and directories below of them are left as-is, even if they do
not match what is requested. The innermost specified directories will have their access mode adjusted to the
what is specified in C<RuntimeDirectoryMode>, C<StateDirectoryMode>,
C<CacheDirectoryMode>, C<LogsDirectoryMode> and
C<ConfigurationDirectoryMode>.

These options imply C<BindPaths> for the specified paths. When combined with
C<RootDirectory> or C<RootImage> these paths always reside on the host and
are mounted from there into the unit's file system namespace.

If C<DynamicUser> is used, the logic for C<CacheDirectory>,
C<LogsDirectory> and C<StateDirectory> is slightly altered: the directories are created below
C</var/cache/private>, C</var/log/private> and C</var/lib/private>,
respectively, which are host directories made inaccessible to
unprivileged users, which ensures that access to these directories cannot be gained through dynamic
user ID recycling. Symbolic links are created to hide this difference in behaviour. Both from
perspective of the host and from inside the unit, the relevant directories hence always appear
directly below C</var/cache>, C</var/log> and
C</var/lib>.

Use C<RuntimeDirectory> to manage one or more runtime directories for the unit and bind
their lifetime to the daemon runtime. This is particularly useful for unprivileged daemons that cannot create
runtime directories in C</run/> due to lack of privileges, and to make sure the runtime
directory is cleaned up automatically after use. For runtime directories that require more complex or different
configuration or lifetime guarantees, please consider using
L<tmpfiles.d(5)>.

The directories defined by these options are always created under the standard paths used by systemd
(C</var/>, C</run/>, C</etc/>, \x{2026}). If the service needs
directories in a different location, a different mechanism has to be used to create them.

L<tmpfiles.d(5)> provides
functionality that overlaps with these options. Using these options is recommended, because the lifetime of
the directories is tied directly to the lifetime of the unit, and it is not necessary to ensure that the
C<tmpfiles.d> configuration is executed before the unit is started.

To remove any of the directories created by these settings, use the systemctl clean
\x{2026} command on the relevant units, see
L<systemctl(1)> for
details.

Example: if a system service unit has the following,

    RuntimeDirectory=foo/bar baz

the service manager creates C</run/foo> (if it does not exist),
C</run/foo/bar>, and C</run/baz>. The
directories C</run/foo/bar> and
C</run/baz> except C</run/foo> are
owned by the user and group specified in C<User> and C<Group>, and removed
when the service is stopped.

Example: if a system service unit has the following,

    RuntimeDirectory=foo/bar
    StateDirectory=aaa/bbb ccc

then the environment variable C<RUNTIME_DIRECTORY> is set with C</run/foo/bar>, and
C<STATE_DIRECTORY> is set with C</var/lib/aaa/bbb:/var/lib/ccc>.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CacheDirectory',
      {
        'description' => "These options take a whitespace-separated list of directory names. The specified
directory names must be relative, and may not include C<..>. If set, when the unit is
started, one or more directories by the specified names will be created (including their parents)
below the locations defined in the following table. Also, the corresponding environment variable will
be defined with the full paths of the directories. If multiple directories are set, then in the
environment variable the paths are concatenated with colon (C<:>).

In case of C<RuntimeDirectory> the innermost subdirectories are removed when
the unit is stopped. It is possible to preserve the specified directories in this case if
C<RuntimeDirectoryPreserve> is configured to C<restart> or
C<yes> (see below). The directories specified with C<StateDirectory>,
C<CacheDirectory>, C<LogsDirectory>,
C<ConfigurationDirectory> are not removed when the unit is stopped.

Except in case of C<ConfigurationDirectory>, the innermost specified directories will be
owned by the user and group specified in C<User> and C<Group>. If the
specified directories already exist and their owning user or group do not match the configured ones, all files
and directories below the specified directories as well as the directories themselves will have their file
ownership recursively changed to match what is configured. As an optimization, if the specified directories are
already owned by the right user and group, files and directories below of them are left as-is, even if they do
not match what is requested. The innermost specified directories will have their access mode adjusted to the
what is specified in C<RuntimeDirectoryMode>, C<StateDirectoryMode>,
C<CacheDirectoryMode>, C<LogsDirectoryMode> and
C<ConfigurationDirectoryMode>.

These options imply C<BindPaths> for the specified paths. When combined with
C<RootDirectory> or C<RootImage> these paths always reside on the host and
are mounted from there into the unit's file system namespace.

If C<DynamicUser> is used, the logic for C<CacheDirectory>,
C<LogsDirectory> and C<StateDirectory> is slightly altered: the directories are created below
C</var/cache/private>, C</var/log/private> and C</var/lib/private>,
respectively, which are host directories made inaccessible to
unprivileged users, which ensures that access to these directories cannot be gained through dynamic
user ID recycling. Symbolic links are created to hide this difference in behaviour. Both from
perspective of the host and from inside the unit, the relevant directories hence always appear
directly below C</var/cache>, C</var/log> and
C</var/lib>.

Use C<RuntimeDirectory> to manage one or more runtime directories for the unit and bind
their lifetime to the daemon runtime. This is particularly useful for unprivileged daemons that cannot create
runtime directories in C</run/> due to lack of privileges, and to make sure the runtime
directory is cleaned up automatically after use. For runtime directories that require more complex or different
configuration or lifetime guarantees, please consider using
L<tmpfiles.d(5)>.

The directories defined by these options are always created under the standard paths used by systemd
(C</var/>, C</run/>, C</etc/>, \x{2026}). If the service needs
directories in a different location, a different mechanism has to be used to create them.

L<tmpfiles.d(5)> provides
functionality that overlaps with these options. Using these options is recommended, because the lifetime of
the directories is tied directly to the lifetime of the unit, and it is not necessary to ensure that the
C<tmpfiles.d> configuration is executed before the unit is started.

To remove any of the directories created by these settings, use the systemctl clean
\x{2026} command on the relevant units, see
L<systemctl(1)> for
details.

Example: if a system service unit has the following,

    RuntimeDirectory=foo/bar baz

the service manager creates C</run/foo> (if it does not exist),
C</run/foo/bar>, and C</run/baz>. The
directories C</run/foo/bar> and
C</run/baz> except C</run/foo> are
owned by the user and group specified in C<User> and C<Group>, and removed
when the service is stopped.

Example: if a system service unit has the following,

    RuntimeDirectory=foo/bar
    StateDirectory=aaa/bbb ccc

then the environment variable C<RUNTIME_DIRECTORY> is set with C</run/foo/bar>, and
C<STATE_DIRECTORY> is set with C</var/lib/aaa/bbb:/var/lib/ccc>.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LogsDirectory',
      {
        'description' => "These options take a whitespace-separated list of directory names. The specified
directory names must be relative, and may not include C<..>. If set, when the unit is
started, one or more directories by the specified names will be created (including their parents)
below the locations defined in the following table. Also, the corresponding environment variable will
be defined with the full paths of the directories. If multiple directories are set, then in the
environment variable the paths are concatenated with colon (C<:>).

In case of C<RuntimeDirectory> the innermost subdirectories are removed when
the unit is stopped. It is possible to preserve the specified directories in this case if
C<RuntimeDirectoryPreserve> is configured to C<restart> or
C<yes> (see below). The directories specified with C<StateDirectory>,
C<CacheDirectory>, C<LogsDirectory>,
C<ConfigurationDirectory> are not removed when the unit is stopped.

Except in case of C<ConfigurationDirectory>, the innermost specified directories will be
owned by the user and group specified in C<User> and C<Group>. If the
specified directories already exist and their owning user or group do not match the configured ones, all files
and directories below the specified directories as well as the directories themselves will have their file
ownership recursively changed to match what is configured. As an optimization, if the specified directories are
already owned by the right user and group, files and directories below of them are left as-is, even if they do
not match what is requested. The innermost specified directories will have their access mode adjusted to the
what is specified in C<RuntimeDirectoryMode>, C<StateDirectoryMode>,
C<CacheDirectoryMode>, C<LogsDirectoryMode> and
C<ConfigurationDirectoryMode>.

These options imply C<BindPaths> for the specified paths. When combined with
C<RootDirectory> or C<RootImage> these paths always reside on the host and
are mounted from there into the unit's file system namespace.

If C<DynamicUser> is used, the logic for C<CacheDirectory>,
C<LogsDirectory> and C<StateDirectory> is slightly altered: the directories are created below
C</var/cache/private>, C</var/log/private> and C</var/lib/private>,
respectively, which are host directories made inaccessible to
unprivileged users, which ensures that access to these directories cannot be gained through dynamic
user ID recycling. Symbolic links are created to hide this difference in behaviour. Both from
perspective of the host and from inside the unit, the relevant directories hence always appear
directly below C</var/cache>, C</var/log> and
C</var/lib>.

Use C<RuntimeDirectory> to manage one or more runtime directories for the unit and bind
their lifetime to the daemon runtime. This is particularly useful for unprivileged daemons that cannot create
runtime directories in C</run/> due to lack of privileges, and to make sure the runtime
directory is cleaned up automatically after use. For runtime directories that require more complex or different
configuration or lifetime guarantees, please consider using
L<tmpfiles.d(5)>.

The directories defined by these options are always created under the standard paths used by systemd
(C</var/>, C</run/>, C</etc/>, \x{2026}). If the service needs
directories in a different location, a different mechanism has to be used to create them.

L<tmpfiles.d(5)> provides
functionality that overlaps with these options. Using these options is recommended, because the lifetime of
the directories is tied directly to the lifetime of the unit, and it is not necessary to ensure that the
C<tmpfiles.d> configuration is executed before the unit is started.

To remove any of the directories created by these settings, use the systemctl clean
\x{2026} command on the relevant units, see
L<systemctl(1)> for
details.

Example: if a system service unit has the following,

    RuntimeDirectory=foo/bar baz

the service manager creates C</run/foo> (if it does not exist),
C</run/foo/bar>, and C</run/baz>. The
directories C</run/foo/bar> and
C</run/baz> except C</run/foo> are
owned by the user and group specified in C<User> and C<Group>, and removed
when the service is stopped.

Example: if a system service unit has the following,

    RuntimeDirectory=foo/bar
    StateDirectory=aaa/bbb ccc

then the environment variable C<RUNTIME_DIRECTORY> is set with C</run/foo/bar>, and
C<STATE_DIRECTORY> is set with C</var/lib/aaa/bbb:/var/lib/ccc>.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ConfigurationDirectory',
      {
        'description' => "These options take a whitespace-separated list of directory names. The specified
directory names must be relative, and may not include C<..>. If set, when the unit is
started, one or more directories by the specified names will be created (including their parents)
below the locations defined in the following table. Also, the corresponding environment variable will
be defined with the full paths of the directories. If multiple directories are set, then in the
environment variable the paths are concatenated with colon (C<:>).

In case of C<RuntimeDirectory> the innermost subdirectories are removed when
the unit is stopped. It is possible to preserve the specified directories in this case if
C<RuntimeDirectoryPreserve> is configured to C<restart> or
C<yes> (see below). The directories specified with C<StateDirectory>,
C<CacheDirectory>, C<LogsDirectory>,
C<ConfigurationDirectory> are not removed when the unit is stopped.

Except in case of C<ConfigurationDirectory>, the innermost specified directories will be
owned by the user and group specified in C<User> and C<Group>. If the
specified directories already exist and their owning user or group do not match the configured ones, all files
and directories below the specified directories as well as the directories themselves will have their file
ownership recursively changed to match what is configured. As an optimization, if the specified directories are
already owned by the right user and group, files and directories below of them are left as-is, even if they do
not match what is requested. The innermost specified directories will have their access mode adjusted to the
what is specified in C<RuntimeDirectoryMode>, C<StateDirectoryMode>,
C<CacheDirectoryMode>, C<LogsDirectoryMode> and
C<ConfigurationDirectoryMode>.

These options imply C<BindPaths> for the specified paths. When combined with
C<RootDirectory> or C<RootImage> these paths always reside on the host and
are mounted from there into the unit's file system namespace.

If C<DynamicUser> is used, the logic for C<CacheDirectory>,
C<LogsDirectory> and C<StateDirectory> is slightly altered: the directories are created below
C</var/cache/private>, C</var/log/private> and C</var/lib/private>,
respectively, which are host directories made inaccessible to
unprivileged users, which ensures that access to these directories cannot be gained through dynamic
user ID recycling. Symbolic links are created to hide this difference in behaviour. Both from
perspective of the host and from inside the unit, the relevant directories hence always appear
directly below C</var/cache>, C</var/log> and
C</var/lib>.

Use C<RuntimeDirectory> to manage one or more runtime directories for the unit and bind
their lifetime to the daemon runtime. This is particularly useful for unprivileged daemons that cannot create
runtime directories in C</run/> due to lack of privileges, and to make sure the runtime
directory is cleaned up automatically after use. For runtime directories that require more complex or different
configuration or lifetime guarantees, please consider using
L<tmpfiles.d(5)>.

The directories defined by these options are always created under the standard paths used by systemd
(C</var/>, C</run/>, C</etc/>, \x{2026}). If the service needs
directories in a different location, a different mechanism has to be used to create them.

L<tmpfiles.d(5)> provides
functionality that overlaps with these options. Using these options is recommended, because the lifetime of
the directories is tied directly to the lifetime of the unit, and it is not necessary to ensure that the
C<tmpfiles.d> configuration is executed before the unit is started.

To remove any of the directories created by these settings, use the systemctl clean
\x{2026} command on the relevant units, see
L<systemctl(1)> for
details.

Example: if a system service unit has the following,

    RuntimeDirectory=foo/bar baz

the service manager creates C</run/foo> (if it does not exist),
C</run/foo/bar>, and C</run/baz>. The
directories C</run/foo/bar> and
C</run/baz> except C</run/foo> are
owned by the user and group specified in C<User> and C<Group>, and removed
when the service is stopped.

Example: if a system service unit has the following,

    RuntimeDirectory=foo/bar
    StateDirectory=aaa/bbb ccc

then the environment variable C<RUNTIME_DIRECTORY> is set with C</run/foo/bar>, and
C<STATE_DIRECTORY> is set with C</var/lib/aaa/bbb:/var/lib/ccc>.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RuntimeDirectoryMode',
      {
        'description' => 'Specifies the access mode of the directories specified in C<RuntimeDirectory>,
C<StateDirectory>, C<CacheDirectory>, C<LogsDirectory>, or
C<ConfigurationDirectory>, respectively, as an octal number.  Defaults to
C<0755>. See "Permissions" in L<path_resolution(7)> for a
discussion of the meaning of permission bits.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StateDirectoryMode',
      {
        'description' => 'Specifies the access mode of the directories specified in C<RuntimeDirectory>,
C<StateDirectory>, C<CacheDirectory>, C<LogsDirectory>, or
C<ConfigurationDirectory>, respectively, as an octal number.  Defaults to
C<0755>. See "Permissions" in L<path_resolution(7)> for a
discussion of the meaning of permission bits.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CacheDirectoryMode',
      {
        'description' => 'Specifies the access mode of the directories specified in C<RuntimeDirectory>,
C<StateDirectory>, C<CacheDirectory>, C<LogsDirectory>, or
C<ConfigurationDirectory>, respectively, as an octal number.  Defaults to
C<0755>. See "Permissions" in L<path_resolution(7)> for a
discussion of the meaning of permission bits.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LogsDirectoryMode',
      {
        'description' => 'Specifies the access mode of the directories specified in C<RuntimeDirectory>,
C<StateDirectory>, C<CacheDirectory>, C<LogsDirectory>, or
C<ConfigurationDirectory>, respectively, as an octal number.  Defaults to
C<0755>. See "Permissions" in L<path_resolution(7)> for a
discussion of the meaning of permission bits.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ConfigurationDirectoryMode',
      {
        'description' => 'Specifies the access mode of the directories specified in C<RuntimeDirectory>,
C<StateDirectory>, C<CacheDirectory>, C<LogsDirectory>, or
C<ConfigurationDirectory>, respectively, as an octal number.  Defaults to
C<0755>. See "Permissions" in L<path_resolution(7)> for a
discussion of the meaning of permission bits.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RuntimeDirectoryPreserve',
      {
        'choice' => [
          'no',
          'yes',
          'restart'
        ],
        'description' => 'Takes a boolean argument or C<restart>.  If set to C<no> (the
default), the directories specified in C<RuntimeDirectory> are always removed when the service
stops. If set to C<restart> the directories are preserved when the service is both automatically
and manually restarted. Here, the automatic restart means the operation specified in
C<Restart>, and manual restart means the one triggered by systemctl restart
foo.service. If set to C<yes>, then the directories are not removed when the service is
stopped. Note that since the runtime directory C</run/> is a mount point of
C<tmpfs>, then for system services the directories specified in
C<RuntimeDirectory> are removed when the system is rebooted.',
        'replace' => {
          '0' => 'no',
          '1' => 'yes',
          'false' => 'no',
          'true' => 'yes'
        },
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'TimeoutCleanSec',
      {
        'description' => "Configures a timeout on the clean-up operation requested through systemctl
clean \x{2026}, see
L<systemctl(1)> for
details. Takes the usual time values and defaults to C<infinity>, i.e. by default
no timeout is applied. If a timeout is configured the clean operation will be aborted forcibly when
the timeout is reached, potentially leaving resources on disk.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ReadWritePaths',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Sets up a new file system namespace for executed processes. These options may be used
to limit access a process has to the file system. Each setting takes a space-separated list of paths
relative to the host\'s root directory (i.e. the system running the service manager). Note that if
paths contain symlinks, they are resolved relative to the root directory set with
C<RootDirectory>/C<RootImage>.

Paths listed in C<ReadWritePaths> are accessible from within the namespace
with the same access modes as from outside of it. Paths listed in C<ReadOnlyPaths>
are accessible for reading only, writing will be refused even if the usual file access controls would
permit this. Nest C<ReadWritePaths> inside of C<ReadOnlyPaths> in
order to provide writable subdirectories within read-only directories. Use
C<ReadWritePaths> in order to allow-list specific paths for write access if
C<ProtectSystem=strict> is used.

Paths listed in C<InaccessiblePaths> will be made inaccessible for processes inside
the namespace along with everything below them in the file system hierarchy. This may be more restrictive than
desired, because it is not possible to nest C<ReadWritePaths>, C<ReadOnlyPaths>,
C<BindPaths>, or C<BindReadOnlyPaths> inside it. For a more flexible option,
see C<TemporaryFileSystem>.

Content in paths listed in C<NoExecPaths> are not executable even if the usual
file access controls would permit this. Nest C<ExecPaths> inside of
C<NoExecPaths> in order to provide executable content within non-executable
directories.

Non-directory paths may be specified as well. These options may be specified more than once,
in which case all paths listed will have limited access from within the namespace. If the empty string is
assigned to this option, the specific list is reset, and all prior assignments have no effect.

Paths in C<ReadWritePaths>, C<ReadOnlyPaths>,
C<InaccessiblePaths>, C<ExecPaths> and
C<NoExecPaths> may be prefixed with C<->, in which case they will be
ignored when they do not exist. If prefixed with C<+> the paths are taken relative to the root
directory of the unit, as configured with C<RootDirectory>/C<RootImage>,
instead of relative to the root directory of the host (see above). When combining C<-> and
C<+> on the same path make sure to specify C<-> first, and C<+>
second.

Note that these settings will disconnect propagation of mounts from the unit\'s processes to the
host. This means that this setting may not be used for services which shall be able to install mount points in
the main mount namespace. For C<ReadWritePaths> and C<ReadOnlyPaths>
propagation in the other direction is not affected, i.e. mounts created on the host generally appear in the
unit processes\' namespace, and mounts removed on the host also disappear there too. In particular, note that
mount propagation from host to unit will result in unmodified mounts to be created in the unit\'s namespace,
i.e. writable mounts appearing on the host will be writable in the unit\'s namespace too, even when propagated
below a path marked with C<ReadOnlyPaths>! Restricting access with these options hence does
not extend to submounts of a directory that are created later on. This means the lock-down offered by that
setting is not complete, and does not offer full protection.

Note that the effect of these settings may be undone by privileged processes. In order to set up an
effective sandboxed environment for a unit it is thus recommended to combine these settings with either
C<CapabilityBoundingSet=~CAP_SYS_ADMIN> or
C<SystemCallFilter=~@mount>.

Simple allow-list example using these directives:

    [Service]
    ReadOnlyPaths=/
    ReadWritePaths=/var /run
    InaccessiblePaths=-/lost+found
    NoExecPaths=/
    ExecPaths=/usr/sbin/my_daemon /usr/lib /usr/lib64

',
        'type' => 'list'
      },
      'ReadOnlyPaths',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Sets up a new file system namespace for executed processes. These options may be used
to limit access a process has to the file system. Each setting takes a space-separated list of paths
relative to the host\'s root directory (i.e. the system running the service manager). Note that if
paths contain symlinks, they are resolved relative to the root directory set with
C<RootDirectory>/C<RootImage>.

Paths listed in C<ReadWritePaths> are accessible from within the namespace
with the same access modes as from outside of it. Paths listed in C<ReadOnlyPaths>
are accessible for reading only, writing will be refused even if the usual file access controls would
permit this. Nest C<ReadWritePaths> inside of C<ReadOnlyPaths> in
order to provide writable subdirectories within read-only directories. Use
C<ReadWritePaths> in order to allow-list specific paths for write access if
C<ProtectSystem=strict> is used.

Paths listed in C<InaccessiblePaths> will be made inaccessible for processes inside
the namespace along with everything below them in the file system hierarchy. This may be more restrictive than
desired, because it is not possible to nest C<ReadWritePaths>, C<ReadOnlyPaths>,
C<BindPaths>, or C<BindReadOnlyPaths> inside it. For a more flexible option,
see C<TemporaryFileSystem>.

Content in paths listed in C<NoExecPaths> are not executable even if the usual
file access controls would permit this. Nest C<ExecPaths> inside of
C<NoExecPaths> in order to provide executable content within non-executable
directories.

Non-directory paths may be specified as well. These options may be specified more than once,
in which case all paths listed will have limited access from within the namespace. If the empty string is
assigned to this option, the specific list is reset, and all prior assignments have no effect.

Paths in C<ReadWritePaths>, C<ReadOnlyPaths>,
C<InaccessiblePaths>, C<ExecPaths> and
C<NoExecPaths> may be prefixed with C<->, in which case they will be
ignored when they do not exist. If prefixed with C<+> the paths are taken relative to the root
directory of the unit, as configured with C<RootDirectory>/C<RootImage>,
instead of relative to the root directory of the host (see above). When combining C<-> and
C<+> on the same path make sure to specify C<-> first, and C<+>
second.

Note that these settings will disconnect propagation of mounts from the unit\'s processes to the
host. This means that this setting may not be used for services which shall be able to install mount points in
the main mount namespace. For C<ReadWritePaths> and C<ReadOnlyPaths>
propagation in the other direction is not affected, i.e. mounts created on the host generally appear in the
unit processes\' namespace, and mounts removed on the host also disappear there too. In particular, note that
mount propagation from host to unit will result in unmodified mounts to be created in the unit\'s namespace,
i.e. writable mounts appearing on the host will be writable in the unit\'s namespace too, even when propagated
below a path marked with C<ReadOnlyPaths>! Restricting access with these options hence does
not extend to submounts of a directory that are created later on. This means the lock-down offered by that
setting is not complete, and does not offer full protection.

Note that the effect of these settings may be undone by privileged processes. In order to set up an
effective sandboxed environment for a unit it is thus recommended to combine these settings with either
C<CapabilityBoundingSet=~CAP_SYS_ADMIN> or
C<SystemCallFilter=~@mount>.

Simple allow-list example using these directives:

    [Service]
    ReadOnlyPaths=/
    ReadWritePaths=/var /run
    InaccessiblePaths=-/lost+found
    NoExecPaths=/
    ExecPaths=/usr/sbin/my_daemon /usr/lib /usr/lib64

',
        'type' => 'list'
      },
      'InaccessiblePaths',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Sets up a new file system namespace for executed processes. These options may be used
to limit access a process has to the file system. Each setting takes a space-separated list of paths
relative to the host\'s root directory (i.e. the system running the service manager). Note that if
paths contain symlinks, they are resolved relative to the root directory set with
C<RootDirectory>/C<RootImage>.

Paths listed in C<ReadWritePaths> are accessible from within the namespace
with the same access modes as from outside of it. Paths listed in C<ReadOnlyPaths>
are accessible for reading only, writing will be refused even if the usual file access controls would
permit this. Nest C<ReadWritePaths> inside of C<ReadOnlyPaths> in
order to provide writable subdirectories within read-only directories. Use
C<ReadWritePaths> in order to allow-list specific paths for write access if
C<ProtectSystem=strict> is used.

Paths listed in C<InaccessiblePaths> will be made inaccessible for processes inside
the namespace along with everything below them in the file system hierarchy. This may be more restrictive than
desired, because it is not possible to nest C<ReadWritePaths>, C<ReadOnlyPaths>,
C<BindPaths>, or C<BindReadOnlyPaths> inside it. For a more flexible option,
see C<TemporaryFileSystem>.

Content in paths listed in C<NoExecPaths> are not executable even if the usual
file access controls would permit this. Nest C<ExecPaths> inside of
C<NoExecPaths> in order to provide executable content within non-executable
directories.

Non-directory paths may be specified as well. These options may be specified more than once,
in which case all paths listed will have limited access from within the namespace. If the empty string is
assigned to this option, the specific list is reset, and all prior assignments have no effect.

Paths in C<ReadWritePaths>, C<ReadOnlyPaths>,
C<InaccessiblePaths>, C<ExecPaths> and
C<NoExecPaths> may be prefixed with C<->, in which case they will be
ignored when they do not exist. If prefixed with C<+> the paths are taken relative to the root
directory of the unit, as configured with C<RootDirectory>/C<RootImage>,
instead of relative to the root directory of the host (see above). When combining C<-> and
C<+> on the same path make sure to specify C<-> first, and C<+>
second.

Note that these settings will disconnect propagation of mounts from the unit\'s processes to the
host. This means that this setting may not be used for services which shall be able to install mount points in
the main mount namespace. For C<ReadWritePaths> and C<ReadOnlyPaths>
propagation in the other direction is not affected, i.e. mounts created on the host generally appear in the
unit processes\' namespace, and mounts removed on the host also disappear there too. In particular, note that
mount propagation from host to unit will result in unmodified mounts to be created in the unit\'s namespace,
i.e. writable mounts appearing on the host will be writable in the unit\'s namespace too, even when propagated
below a path marked with C<ReadOnlyPaths>! Restricting access with these options hence does
not extend to submounts of a directory that are created later on. This means the lock-down offered by that
setting is not complete, and does not offer full protection.

Note that the effect of these settings may be undone by privileged processes. In order to set up an
effective sandboxed environment for a unit it is thus recommended to combine these settings with either
C<CapabilityBoundingSet=~CAP_SYS_ADMIN> or
C<SystemCallFilter=~@mount>.

Simple allow-list example using these directives:

    [Service]
    ReadOnlyPaths=/
    ReadWritePaths=/var /run
    InaccessiblePaths=-/lost+found
    NoExecPaths=/
    ExecPaths=/usr/sbin/my_daemon /usr/lib /usr/lib64

',
        'type' => 'list'
      },
      'ExecPaths',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Sets up a new file system namespace for executed processes. These options may be used
to limit access a process has to the file system. Each setting takes a space-separated list of paths
relative to the host\'s root directory (i.e. the system running the service manager). Note that if
paths contain symlinks, they are resolved relative to the root directory set with
C<RootDirectory>/C<RootImage>.

Paths listed in C<ReadWritePaths> are accessible from within the namespace
with the same access modes as from outside of it. Paths listed in C<ReadOnlyPaths>
are accessible for reading only, writing will be refused even if the usual file access controls would
permit this. Nest C<ReadWritePaths> inside of C<ReadOnlyPaths> in
order to provide writable subdirectories within read-only directories. Use
C<ReadWritePaths> in order to allow-list specific paths for write access if
C<ProtectSystem=strict> is used.

Paths listed in C<InaccessiblePaths> will be made inaccessible for processes inside
the namespace along with everything below them in the file system hierarchy. This may be more restrictive than
desired, because it is not possible to nest C<ReadWritePaths>, C<ReadOnlyPaths>,
C<BindPaths>, or C<BindReadOnlyPaths> inside it. For a more flexible option,
see C<TemporaryFileSystem>.

Content in paths listed in C<NoExecPaths> are not executable even if the usual
file access controls would permit this. Nest C<ExecPaths> inside of
C<NoExecPaths> in order to provide executable content within non-executable
directories.

Non-directory paths may be specified as well. These options may be specified more than once,
in which case all paths listed will have limited access from within the namespace. If the empty string is
assigned to this option, the specific list is reset, and all prior assignments have no effect.

Paths in C<ReadWritePaths>, C<ReadOnlyPaths>,
C<InaccessiblePaths>, C<ExecPaths> and
C<NoExecPaths> may be prefixed with C<->, in which case they will be
ignored when they do not exist. If prefixed with C<+> the paths are taken relative to the root
directory of the unit, as configured with C<RootDirectory>/C<RootImage>,
instead of relative to the root directory of the host (see above). When combining C<-> and
C<+> on the same path make sure to specify C<-> first, and C<+>
second.

Note that these settings will disconnect propagation of mounts from the unit\'s processes to the
host. This means that this setting may not be used for services which shall be able to install mount points in
the main mount namespace. For C<ReadWritePaths> and C<ReadOnlyPaths>
propagation in the other direction is not affected, i.e. mounts created on the host generally appear in the
unit processes\' namespace, and mounts removed on the host also disappear there too. In particular, note that
mount propagation from host to unit will result in unmodified mounts to be created in the unit\'s namespace,
i.e. writable mounts appearing on the host will be writable in the unit\'s namespace too, even when propagated
below a path marked with C<ReadOnlyPaths>! Restricting access with these options hence does
not extend to submounts of a directory that are created later on. This means the lock-down offered by that
setting is not complete, and does not offer full protection.

Note that the effect of these settings may be undone by privileged processes. In order to set up an
effective sandboxed environment for a unit it is thus recommended to combine these settings with either
C<CapabilityBoundingSet=~CAP_SYS_ADMIN> or
C<SystemCallFilter=~@mount>.

Simple allow-list example using these directives:

    [Service]
    ReadOnlyPaths=/
    ReadWritePaths=/var /run
    InaccessiblePaths=-/lost+found
    NoExecPaths=/
    ExecPaths=/usr/sbin/my_daemon /usr/lib /usr/lib64

',
        'type' => 'list'
      },
      'NoExecPaths',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Sets up a new file system namespace for executed processes. These options may be used
to limit access a process has to the file system. Each setting takes a space-separated list of paths
relative to the host\'s root directory (i.e. the system running the service manager). Note that if
paths contain symlinks, they are resolved relative to the root directory set with
C<RootDirectory>/C<RootImage>.

Paths listed in C<ReadWritePaths> are accessible from within the namespace
with the same access modes as from outside of it. Paths listed in C<ReadOnlyPaths>
are accessible for reading only, writing will be refused even if the usual file access controls would
permit this. Nest C<ReadWritePaths> inside of C<ReadOnlyPaths> in
order to provide writable subdirectories within read-only directories. Use
C<ReadWritePaths> in order to allow-list specific paths for write access if
C<ProtectSystem=strict> is used.

Paths listed in C<InaccessiblePaths> will be made inaccessible for processes inside
the namespace along with everything below them in the file system hierarchy. This may be more restrictive than
desired, because it is not possible to nest C<ReadWritePaths>, C<ReadOnlyPaths>,
C<BindPaths>, or C<BindReadOnlyPaths> inside it. For a more flexible option,
see C<TemporaryFileSystem>.

Content in paths listed in C<NoExecPaths> are not executable even if the usual
file access controls would permit this. Nest C<ExecPaths> inside of
C<NoExecPaths> in order to provide executable content within non-executable
directories.

Non-directory paths may be specified as well. These options may be specified more than once,
in which case all paths listed will have limited access from within the namespace. If the empty string is
assigned to this option, the specific list is reset, and all prior assignments have no effect.

Paths in C<ReadWritePaths>, C<ReadOnlyPaths>,
C<InaccessiblePaths>, C<ExecPaths> and
C<NoExecPaths> may be prefixed with C<->, in which case they will be
ignored when they do not exist. If prefixed with C<+> the paths are taken relative to the root
directory of the unit, as configured with C<RootDirectory>/C<RootImage>,
instead of relative to the root directory of the host (see above). When combining C<-> and
C<+> on the same path make sure to specify C<-> first, and C<+>
second.

Note that these settings will disconnect propagation of mounts from the unit\'s processes to the
host. This means that this setting may not be used for services which shall be able to install mount points in
the main mount namespace. For C<ReadWritePaths> and C<ReadOnlyPaths>
propagation in the other direction is not affected, i.e. mounts created on the host generally appear in the
unit processes\' namespace, and mounts removed on the host also disappear there too. In particular, note that
mount propagation from host to unit will result in unmodified mounts to be created in the unit\'s namespace,
i.e. writable mounts appearing on the host will be writable in the unit\'s namespace too, even when propagated
below a path marked with C<ReadOnlyPaths>! Restricting access with these options hence does
not extend to submounts of a directory that are created later on. This means the lock-down offered by that
setting is not complete, and does not offer full protection.

Note that the effect of these settings may be undone by privileged processes. In order to set up an
effective sandboxed environment for a unit it is thus recommended to combine these settings with either
C<CapabilityBoundingSet=~CAP_SYS_ADMIN> or
C<SystemCallFilter=~@mount>.

Simple allow-list example using these directives:

    [Service]
    ReadOnlyPaths=/
    ReadWritePaths=/var /run
    InaccessiblePaths=-/lost+found
    NoExecPaths=/
    ExecPaths=/usr/sbin/my_daemon /usr/lib /usr/lib64

',
        'type' => 'list'
      },
      'TemporaryFileSystem',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Takes a space-separated list of mount points for temporary file systems (tmpfs). If set, a new file
system namespace is set up for executed processes, and a temporary file system is mounted on each mount point.
This option may be specified more than once, in which case temporary file systems are mounted on all listed mount
points. If the empty string is assigned to this option, the list is reset, and all prior assignments have no effect.
Each mount point may optionally be suffixed with a colon (C<:>) and mount options such as
C<size=10%> or C<ro>. By default, each temporary file system is mounted
with C<nodev,strictatime,mode=0755>. These can be disabled by explicitly specifying the corresponding
mount options, e.g., C<dev> or C<nostrictatime>.

This is useful to hide files or directories not relevant to the processes invoked by the unit, while necessary
files or directories can be still accessed by combining with C<BindPaths> or
C<BindReadOnlyPaths>:

Example: if a unit has the following,

    TemporaryFileSystem=/var:ro
    BindReadOnlyPaths=/var/lib/systemd

then the invoked processes by the unit cannot see any files or directories under C</var/> except for
C</var/lib/systemd> or its contents.',
        'type' => 'list'
      },
      'PrivateTmp',
      {
        'description' => 'Takes a boolean argument. If true, sets up a new file system namespace for the
executed processes and mounts private C</tmp/> and C</var/tmp/>
directories inside it that are not shared by processes outside of the namespace. This is useful to
secure access to temporary files of the process, but makes sharing between processes via
C</tmp/> or C</var/tmp/> impossible. If true, all temporary files
created by a service in these directories will be removed after the service is stopped. Defaults to
false. It is possible to run two or more units within the same private C</tmp/> and
C</var/tmp/> namespace by using the C<JoinsNamespaceOf> directive,
see L<systemd.unit(5)>
for details. This setting is implied if C<DynamicUser> is set. For this setting the
same restrictions regarding mount propagation and privileges apply as for
C<ReadOnlyPaths> and related calls, see above. Enabling this setting has the side
effect of adding C<Requires> and C<After> dependencies on all mount
units necessary to access C</tmp/> and C</var/tmp/>. Moreover an
implicitly C<After> ordering on
L<systemd-tmpfiles-setup.service(8)>
is added.

Note that the implementation of this setting might be impossible (for example if mount namespaces are not
available), and the unit should be written in a way that does not solely rely on this setting for
security.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PrivateDevices',
      {
        'description' => 'Takes a boolean argument. If true, sets up a new C</dev/> mount for the
executed processes and only adds API pseudo devices such as C</dev/null>,
C</dev/zero> or C</dev/random> (as well as the pseudo TTY subsystem) to it,
but no physical devices such as C</dev/sda>, system memory C</dev/mem>,
system ports C</dev/port> and others. This is useful to securely turn off physical device
access by the executed process. Defaults to false. Enabling this option will install a system call filter to
block low-level I/O system calls that are grouped in the C<@raw-io> set, will also remove
C<CAP_MKNOD> and C<CAP_SYS_RAWIO> from the capability bounding set for the
unit (see above), and set C<DevicePolicy=closed> (see
L<systemd.resource-control(5)>
for details). Note that using this setting will disconnect propagation of mounts from the service to the host
(propagation in the opposite direction continues to work). This means that this setting may not be used for
services which shall be able to install mount points in the main mount namespace. The new
C</dev/> will be mounted read-only and \'noexec\'. The latter may break old programs which try
to set up executable memory by using
L<mmap(2)> of
C</dev/zero> instead of using C<MAP_ANON>. For this setting the same
restrictions regarding mount propagation and privileges apply as for C<ReadOnlyPaths> and
related calls, see above. If turned on and if running in user mode, or in system mode, but without the
C<CAP_SYS_ADMIN> capability (e.g. setting C<User>),
C<NoNewPrivileges=yes> is implied.

Note that the implementation of this setting might be impossible (for example if mount namespaces are not
available), and the unit should be written in a way that does not solely rely on this setting for
security.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PrivateNetwork',
      {
        'description' => 'Takes a boolean argument. If true, sets up a new network namespace for the executed processes
and configures only the loopback network device C<lo> inside it. No other network devices will
be available to the executed process. This is useful to turn off network access by the executed process.
Defaults to false. It is possible to run two or more units within the same private network namespace by using
the C<JoinsNamespaceOf> directive, see
L<systemd.unit(5)> for
details. Note that this option will disconnect all socket families from the host, including
C<AF_NETLINK> and C<AF_UNIX>. Effectively, for
C<AF_NETLINK> this means that device configuration events received from
L<systemd-udevd.service(8)> are
not delivered to the unit\'s processes. And for C<AF_UNIX> this has the effect that
C<AF_UNIX> sockets in the abstract socket namespace of the host will become unavailable to
the unit\'s processes (however, those located in the file system will continue to be accessible).

Note that the implementation of this setting might be impossible (for example if network namespaces are
not available), and the unit should be written in a way that does not solely rely on this setting for
security.

When this option is used on a socket unit any sockets bound on behalf of this unit will be
bound within a private network namespace. This may be combined with
C<JoinsNamespaceOf> to listen on sockets inside of network namespaces of other
services.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'NetworkNamespacePath',
      {
        'description' => 'Takes an absolute file system path refererring to a Linux network namespace
pseudo-file (i.e. a file like C</proc/$PID/ns/net> or a bind mount or symlink to
one). When set the invoked processes are added to the network namespace referenced by that path. The
path has to point to a valid namespace file at the moment the processes are forked off. If this
option is used C<PrivateNetwork> has no effect. If this option is used together with
C<JoinsNamespaceOf> then it only has an effect if this unit is started before any of
the listed units that have C<PrivateNetwork> or
C<NetworkNamespacePath> configured, as otherwise the network namespace of those
units is reused.

When this option is used on a socket unit any sockets bound on behalf of this unit will be
bound within the specified network namespace.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PrivateIPC',
      {
        'description' => 'Takes a boolean argument. If true, sets up a new IPC namespace for the executed processes.
Each IPC namespace has its own set of System V IPC identifiers and its own POSIX message queue file system.
This is useful to avoid name clash of IPC identifiers. Defaults to false. It is possible to run two or
more units within the same private IPC namespace by using the C<JoinsNamespaceOf> directive,
see L<systemd.unit(5)> for
details.

Note that IPC namespacing does not have an effect on
C<AF_UNIX> sockets, which are the most common
form of IPC used on Linux. Instead, C<AF_UNIX>
sockets in the file system are subject to mount namespacing, and
those in the abstract namespace are subject to network namespacing.
IPC namespacing only has an effect on SysV IPC (which is mostly
legacy) as well as POSIX message queues (for which
C<AF_UNIX>/C<SOCK_SEQPACKET>
sockets are typically a better replacement). IPC namespacing also
has no effect on POSIX shared memory (which is subject to mount
namespacing) either. See
L<ipc_namespaces(7)> for
the details.

Note that the implementation of this setting might be impossible (for example if IPC namespaces are
not available), and the unit should be written in a way that does not solely rely on this setting for
security.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'IPCNamespacePath',
      {
        'description' => 'Takes an absolute file system path refererring to a Linux IPC namespace
pseudo-file (i.e. a file like C</proc/$PID/ns/ipc> or a bind mount or symlink to
one). When set the invoked processes are added to the network namespace referenced by that path. The
path has to point to a valid namespace file at the moment the processes are forked off. If this
option is used C<PrivateIPC> has no effect. If this option is used together with
C<JoinsNamespaceOf> then it only has an effect if this unit is started before any of
the listed units that have C<PrivateIPC> or
C<IPCNamespacePath> configured, as otherwise the network namespace of those
units is reused.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PrivateUsers',
      {
        'description' => 'Takes a boolean argument. If true, sets up a new user namespace for the executed processes and
configures a minimal user and group mapping, that maps the C<root> user and group as well as
the unit\'s own user and group to themselves and everything else to the C<nobody> user and
group. This is useful to securely detach the user and group databases used by the unit from the rest of the
system, and thus to create an effective sandbox environment. All files, directories, processes, IPC objects and
other resources owned by users/groups not equaling C<root> or the unit\'s own will stay visible
from within the unit but appear owned by the C<nobody> user and group. If this mode is enabled,
all unit processes are run without privileges in the host user namespace (regardless if the unit\'s own
user/group is C<root> or not). Specifically this means that the process will have zero process
capabilities on the host\'s user namespace, but full capabilities within the service\'s user namespace. Settings
such as C<CapabilityBoundingSet> will affect only the latter, and there\'s no way to acquire
additional capabilities in the host\'s user namespace. Defaults to off.

When this setting is set up by a per-user instance of the service manager, the mapping of the
C<root> user and group to itself is omitted (unless the user manager is root).
Additionally, in the per-user instance manager case, the
user namespace will be set up before most other namespaces. This means that combining
C<PrivateUsers>C<true> with other namespaces will enable use of features not
normally supported by the per-user instances of the service manager.

This setting is particularly useful in conjunction with
C<RootDirectory>/C<RootImage>, as the need to synchronize the user and group
databases in the root directory and on the host is reduced, as the only users and groups who need to be matched
are C<root>, C<nobody> and the unit\'s own user and group.

Note that the implementation of this setting might be impossible (for example if user namespaces are not
available), and the unit should be written in a way that does not solely rely on this setting for
security.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'ProtectHostname',
      {
        'description' => 'Takes a boolean argument. When set, sets up a new UTS namespace for the executed
processes. In addition, changing hostname or domainname is prevented. Defaults to off.

Note that the implementation of this setting might be impossible (for example if UTS namespaces
are not available), and the unit should be written in a way that does not solely rely on this setting
for security.

Note that when this option is enabled for a service hostname changes no longer propagate from
the system into the service, it is hence not suitable for services that need to take notice of system
hostname changes dynamically.

If this setting is on, but the unit doesn\'t have the C<CAP_SYS_ADMIN>
capability (e.g. services for which C<User> is set),
C<NoNewPrivileges=yes> is implied.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'ProtectClock',
      {
        'description' => 'Takes a boolean argument. If set, writes to the hardware clock or system clock will be denied.
It is recommended to turn this on for most services that do not need modify the clock. Defaults to off. Enabling
this option removes C<CAP_SYS_TIME> and C<CAP_WAKE_ALARM> from the
capability bounding set for this unit, installs a system call filter to block calls that can set the
clock, and C<DeviceAllow=char-rtc r> is implied. This ensures C</dev/rtc0>,
C</dev/rtc1>, etc. are made read-only to the service. See
L<systemd.resource-control(5)>
for the details about C<DeviceAllow>. If this setting is on, but the unit
doesn\'t have the C<CAP_SYS_ADMIN> capability (e.g. services for which
C<User> is set), C<NoNewPrivileges=yes> is implied.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'ProtectKernelTunables',
      {
        'description' => 'Takes a boolean argument. If true, kernel variables accessible through
C</proc/sys/>, C</sys/>, C</proc/sysrq-trigger>,
C</proc/latency_stats>, C</proc/acpi>,
C</proc/timer_stats>, C</proc/fs> and C</proc/irq> will
be made read-only to all processes of the unit. Usually, tunable kernel variables should be initialized only at
boot-time, for example with the
L<sysctl.d(5)> mechanism. Few
services need to write to these at runtime; it is hence recommended to turn this on for most services. For this
setting the same restrictions regarding mount propagation and privileges apply as for
C<ReadOnlyPaths> and related calls, see above. Defaults to off. If this
setting is on, but the unit doesn\'t have the C<CAP_SYS_ADMIN> capability
(e.g. services for which C<User> is set),
C<NoNewPrivileges=yes> is implied. Note that this option does not prevent
indirect changes to kernel tunables effected by IPC calls to other processes. However,
C<InaccessiblePaths> may be used to make relevant IPC file system objects
inaccessible. If C<ProtectKernelTunables> is set,
C<MountAPIVFS=yes> is implied.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'ProtectKernelModules',
      {
        'description' => 'Takes a boolean argument. If true, explicit module loading will be denied. This allows
module load and unload operations to be turned off on modular kernels. It is recommended to turn this on for most services
that do not need special file systems or extra kernel modules to work. Defaults to off. Enabling this option
removes C<CAP_SYS_MODULE> from the capability bounding set for the unit, and installs a
system call filter to block module system calls, also C</usr/lib/modules> is made
inaccessible. For this setting the same restrictions regarding mount propagation and privileges apply as for
C<ReadOnlyPaths> and related calls, see above.  Note that limited automatic module loading due
to user configuration or kernel mapping tables might still happen as side effect of requested user operations,
both privileged and unprivileged. To disable module auto-load feature please see
L<sysctl.d(5)>C<kernel.modules_disabled> mechanism and
C</proc/sys/kernel/modules_disabled> documentation. If this setting is on,
but the unit doesn\'t have the C<CAP_SYS_ADMIN> capability (e.g. services for
which C<User> is set), C<NoNewPrivileges=yes> is implied.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'ProtectKernelLogs',
      {
        'description' => 'Takes a boolean argument. If true, access to the kernel log ring buffer will be denied. It is
recommended to turn this on for most services that do not need to read from or write to the kernel log ring
buffer. Enabling this option removes C<CAP_SYSLOG> from the capability bounding set for this
unit, and installs a system call filter to block the
L<syslog(2)>
system call (not to be confused with the libc API
L<syslog(3)>
for userspace logging). The kernel exposes its log buffer to userspace via C</dev/kmsg> and
C</proc/kmsg>. If enabled, these are made inaccessible to all the processes in the unit.
If this setting is on, but the unit doesn\'t have the C<CAP_SYS_ADMIN>
capability (e.g. services for which C<User> is set),
C<NoNewPrivileges=yes> is implied.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'ProtectControlGroups',
      {
        'description' => 'Takes a boolean argument. If true, the Linux Control Groups (L<cgroups(7)>) hierarchies
accessible through C</sys/fs/cgroup/> will be made read-only to all processes of the
unit. Except for container managers no services should require write access to the control groups hierarchies;
it is hence recommended to turn this on for most services. For this setting the same restrictions regarding
mount propagation and privileges apply as for C<ReadOnlyPaths> and related calls, see
above. Defaults to off. If C<ProtectControlGroups> is set, C<MountAPIVFS=yes>
is implied.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'RestrictAddressFamilies',
      {
        'description' => 'Restricts the set of socket address families accessible to the processes of this
unit. Takes C<none>, or a space-separated list of address family names to
allow-list, such as C<AF_UNIX>, C<AF_INET> or
C<AF_INET6>. When C<none> is specified, then all address
families will be denied. When prefixed with C<~> the listed address
families will be applied as deny list, otherwise as allow list. Note that this restricts access
to the
L<socket(2)>
system call only. Sockets passed into the process by other means (for example, by using socket
activation with socket units, see
L<systemd.socket(5)>)
are unaffected. Also, sockets created with socketpair() (which creates connected
AF_UNIX sockets only) are unaffected. Note that this option has no effect on 32-bit x86, s390, s390x,
mips, mips-le, ppc, ppc-le, ppc64, ppc64-le and is ignored (but works correctly on other ABIs,
including x86-64). Note that on systems supporting multiple ABIs (such as x86/x86-64) it is
recommended to turn off alternative ABIs for services, so that they cannot be used to circumvent the
restrictions of this option. Specifically, it is recommended to combine this option with
C<SystemCallArchitectures=native> or similar. If running in user mode, or in system
mode, but without the C<CAP_SYS_ADMIN> capability (e.g. setting
C<User>), C<NoNewPrivileges=yes> is implied. By default, no
restrictions apply, all address families are accessible to processes. If assigned the empty string,
any previous address family restriction changes are undone. This setting does not affect commands
prefixed with C<+>.

Use this option to limit exposure of processes to remote access, in particular via exotic and sensitive
network protocols, such as C<AF_PACKET>. Note that in most cases, the local
C<AF_UNIX> address family should be included in the configured allow list as it is frequently
used for local communication, including for
L<syslog(2)>
logging.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RestrictNamespaces',
      {
        'description' => "Restricts access to Linux namespace functionality for the processes of this unit. For details
about Linux namespaces, see L<namespaces(7)>. Either
takes a boolean argument, or a space-separated list of namespace type identifiers. If false (the default), no
restrictions on namespace creation and switching are made. If true, access to any kind of namespacing is
prohibited. Otherwise, a space-separated list of namespace type identifiers must be specified, consisting of
any combination of: C<cgroup>, C<ipc>, C<net>,
C<mnt>, C<pid>, C<user> and C<uts>. Any
namespace type listed is made accessible to the unit's processes, access to namespace types not listed is
prohibited (allow-listing). By prepending the list with a single tilde character (C<~>) the
effect may be inverted: only the listed namespace types will be made inaccessible, all unlisted ones are
permitted (deny-listing). If the empty string is assigned, the default namespace restrictions are applied,
which is equivalent to false. This option may appear more than once, in which case the namespace types are
merged by C<OR>, or by C<AND> if the lines are prefixed with
C<~> (see examples below). Internally, this setting limits access to the
L<unshare(2)>,
L<clone(2)> and
L<setns(2)> system calls, taking
the specified flags parameters into account. Note that \x{2014} if this option is used \x{2014} in addition to restricting
creation and switching of the specified types of namespaces (or all of them, if true) access to the
setns() system call with a zero flags parameter is prohibited.  This setting is only
supported on x86, x86-64, mips, mips-le, mips64, mips64-le, mips64-n32, mips64-le-n32, ppc64, ppc64-le, s390
and s390x, and enforces no restrictions on other architectures. If running in user mode, or in system mode, but
without the C<CAP_SYS_ADMIN> capability (e.g. setting C<User>),
C<NoNewPrivileges=yes> is implied.

Example: if a unit has the following,

    RestrictNamespaces=cgroup ipc
    RestrictNamespaces=cgroup net

then C<cgroup>, C<ipc>, and C<net> are set.
If the second line is prefixed with C<~>, e.g.,

    RestrictNamespaces=cgroup ipc
    RestrictNamespaces=~cgroup net

then, only C<ipc> is set.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LockPersonality',
      {
        'description' => 'Takes a boolean argument. If set, locks down the L<personality(2)> system
call so that the kernel execution domain may not be changed from the default or the personality selected with
C<Personality> directive. This may be useful to improve security, because odd personality
emulations may be poorly tested and source of vulnerabilities. If running in user mode, or in system mode, but
without the C<CAP_SYS_ADMIN> capability (e.g. setting C<User>),
C<NoNewPrivileges=yes> is implied.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'MemoryDenyWriteExecute',
      {
        'description' => 'Takes a boolean argument. If set, attempts to create memory mappings that are writable and
executable at the same time, or to change existing memory mappings to become executable, or mapping shared
memory segments as executable are prohibited.  Specifically, a system call filter is added that rejects
L<mmap(2)> system calls with both
C<PROT_EXEC> and C<PROT_WRITE> set,
L<mprotect(2)> or
L<pkey_mprotect(2)> system calls
with C<PROT_EXEC> set and
L<shmat(2)> system calls with
C<SHM_EXEC> set. Note that this option is incompatible with programs and libraries that
generate program code dynamically at runtime, including JIT execution engines, executable stacks, and code
"trampoline" feature of various C compilers. This option improves service security, as it makes harder for
software exploits to change running code dynamically. However, the protection can be circumvented, if
the service can write to a filesystem, which is not mounted with C<noexec> (such as
C</dev/shm>), or it can use memfd_create().  This can be
prevented by making such file systems inaccessible to the service
(e.g. C<InaccessiblePaths=/dev/shm>) and installing further system call filters
(C<SystemCallFilter=~memfd_create>). Note that this feature is fully available on
x86-64, and partially on x86. Specifically, the shmat() protection is not
available on x86. Note that on systems supporting multiple ABIs (such as x86/x86-64) it is
recommended to turn off alternative ABIs for services, so that they cannot be used to circumvent the
restrictions of this option. Specifically, it is recommended to combine this option with
C<SystemCallArchitectures=native> or similar. If running in user mode, or in system
mode, but without the C<CAP_SYS_ADMIN> capability (e.g. setting
C<User>), C<NoNewPrivileges=yes> is implied.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'RestrictRealtime',
      {
        'description' => 'Takes a boolean argument. If set, any attempts to enable realtime scheduling in a process of
the unit are refused. This restricts access to realtime task scheduling policies such as
C<SCHED_FIFO>, C<SCHED_RR> or C<SCHED_DEADLINE>. See
L<sched(7)>
for details about these scheduling policies. If running in user mode, or in system mode, but without the
C<CAP_SYS_ADMIN> capability (e.g. setting C<User>),
C<NoNewPrivileges=yes> is implied. Realtime scheduling policies may be used to monopolize CPU
time for longer periods of time, and may hence be used to lock up or otherwise trigger Denial-of-Service
situations on the system. It is hence recommended to restrict access to realtime scheduling to the few programs
that actually require them. Defaults to off.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'RestrictSUIDSGID',
      {
        'description' => 'Takes a boolean argument. If set, any attempts to set the set-user-ID (SUID) or
set-group-ID (SGID) bits on files or directories will be denied (for details on these bits see
L<inode(7)>). If
running in user mode, or in system mode, but without the C<CAP_SYS_ADMIN>
capability (e.g. setting C<User>), C<NoNewPrivileges=yes> is
implied. As the SUID/SGID bits are mechanisms to elevate privileges, and allows users to acquire the
identity of other users, it is recommended to restrict creation of SUID/SGID files to the few
programs that actually require them. Note that this restricts marking of any type of file system
object with these bits, including both regular files and directories (where the SGID is a different
meaning than for files, see documentation). This option is implied if C<DynamicUser>
is enabled. Defaults to off.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'RemoveIPC',
      {
        'description' => 'Takes a boolean parameter. If set, all System V and POSIX IPC objects owned by the user and
group the processes of this unit are run as are removed when the unit is stopped. This setting only has an
effect if at least one of C<User>, C<Group> and
C<DynamicUser> are used. It has no effect on IPC objects owned by the root user. Specifically,
this removes System V semaphores, as well as System V and POSIX shared memory segments and message queues. If
multiple units use the same user or group the IPC objects are removed when the last of these units is
stopped. This setting is implied if C<DynamicUser> is set.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PrivateMounts',
      {
        'description' => "Takes a boolean parameter. If set, the processes of this unit will be run in their own private
file system (mount) namespace with all mount propagation from the processes towards the host's main file system
namespace turned off. This means any file system mount points established or removed by the unit's processes
will be private to them and not be visible to the host. However, file system mount points established or
removed on the host will be propagated to the unit's processes. See L<mount_namespaces(7)> for
details on file system namespaces. Defaults to off.

When turned on, this executes three operations for each invoked process: a new
C<CLONE_NEWNS> namespace is created, after which all existing mounts are remounted to
C<MS_SLAVE> to disable propagation from the unit's processes to the host (but leaving
propagation in the opposite direction in effect). Finally, the mounts are remounted again to the propagation
mode configured with C<MountFlags>, see below.

File system namespaces are set up individually for each process forked off by the service manager. Mounts
established in the namespace of the process created by C<ExecStartPre> will hence be cleaned
up automatically as soon as that process exits and will not be available to subsequent processes forked off for
C<ExecStart> (and similar applies to the various other commands configured for
units). Similarly, C<JoinsNamespaceOf> does not permit sharing kernel mount namespaces between
units, it only enables sharing of the C</tmp/> and C</var/tmp/>
directories.

Other file system namespace unit settings \x{2014} C<PrivateMounts>,
C<PrivateTmp>, C<PrivateDevices>, C<ProtectSystem>,
C<ProtectHome>, C<ReadOnlyPaths>, C<InaccessiblePaths>,
C<ReadWritePaths>, \x{2026} \x{2014} also enable file system namespacing in a fashion equivalent to this
option. Hence it is primarily useful to explicitly request this behaviour if none of the other settings are
used.",
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'MountFlags',
      {
        'description' => "Takes a mount propagation setting: C<shared>, C<slave> or
C<private>, which controls whether file system mount points in the file system namespaces set up
for this unit's processes will receive or propagate mounts and unmounts from other file system namespaces. See
L<mount(2)>
for details on mount propagation, and the three propagation flags in particular.

This setting only controls the final propagation setting in effect on all mount
points of the file system namespace created for each process of this unit. Other file system namespacing unit
settings (see the discussion in C<PrivateMounts> above) will implicitly disable mount and
unmount propagation from the unit's processes towards the host by changing the propagation setting of all mount
points in the unit's file system namespace to C<slave> first. Setting this option to
C<shared> does not reestablish propagation in that case.

If not set \x{2013} but file system namespaces are enabled through another file system namespace unit setting \x{2013}
C<shared> mount propagation is used, but \x{2014} as mentioned \x{2014} as C<slave> is applied
first, propagation from the unit's processes to the host is still turned off.

It is not recommended to use C<private> mount propagation for units, as this means
temporary mounts (such as removable media) of the host will stay mounted and thus indefinitely busy in forked
off processes, as unmount propagation events won't be received by the file system namespace of the unit.

Usually, it is best to leave this setting unmodified, and use higher level file system namespacing
options instead, in particular C<PrivateMounts>, see above.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SystemCallFilter',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Takes a space-separated list of system call names. If this setting is used, all
system calls executed by the unit processes except for the listed ones will result in immediate
process termination with the C<SIGSYS> signal (allow-listing). (See
C<SystemCallErrorNumber> below for changing the default action). If the first
character of the list is C<~>, the effect is inverted: only the listed system calls
will result in immediate process termination (deny-listing). Deny-listed system calls and system call
groups may optionally be suffixed with a colon (C<:>) and C<errno>
error number (between 0 and 4095) or errno name such as C<EPERM>,
C<EACCES> or C<EUCLEAN> (see L<errno(3)> for a
full list). This value will be returned when a deny-listed system call is triggered, instead of
terminating the processes immediately. Special setting C<kill> can be used to
explicitly specify killing. This value takes precedence over the one given in
C<SystemCallErrorNumber>, see below.  If running in user mode, or in system mode,
but without the C<CAP_SYS_ADMIN> capability (e.g. setting
C<User>), C<NoNewPrivileges=yes> is implied. This feature
makes use of the Secure Computing Mode 2 interfaces of the kernel ('seccomp filtering') and is useful
for enforcing a minimal sandboxing environment. Note that the execve(),
exit(), exit_group(), getrlimit(),
rt_sigreturn(), sigreturn() system calls and the system calls
for querying time and sleeping are implicitly allow-listed and do not need to be listed
explicitly. This option may be specified more than once, in which case the filter masks are
merged. If the empty string is assigned, the filter is reset, all prior assignments will have no
effect. This does not affect commands prefixed with C<+>.

Note that on systems supporting multiple ABIs (such as x86/x86-64) it is recommended to turn off
alternative ABIs for services, so that they cannot be used to circumvent the restrictions of this
option. Specifically, it is recommended to combine this option with
C<SystemCallArchitectures=native> or similar.

Note that strict system call filters may impact execution and error handling code paths of the service
invocation. Specifically, access to the execve() system call is required for the execution
of the service binary \x{2014} if it is blocked service invocation will necessarily fail. Also, if execution of the
service binary fails for some reason (for example: missing service executable), the error handling logic might
require access to an additional set of system calls in order to process and log this failure correctly. It
might be necessary to temporarily disable system call filters in order to simplify debugging of such
failures.

If you specify both types of this option (i.e.  allow-listing and deny-listing), the first
encountered will take precedence and will dictate the default action (termination or approval of a
system call). Then the next occurrences of this option will add or delete the listed system calls
from the set of the filtered system calls, depending of its type and the default action. (For
example, if you have started with an allow list rule for read() and
write(), and right after it add a deny list rule for write(),
then write() will be removed from the set.)

As the number of possible system calls is large, predefined sets of system calls are provided.  A set
starts with C<\@> character, followed by name of the set.
Currently predefined system call setsSetDescription\@aioAsynchronous I/O (L<io_setup(2)>, L<io_submit(2)>, and related calls)\@basic-ioSystem calls for basic I/O: reading, writing, seeking, file descriptor duplication and closing (L<read(2)>, L<write(2)>, and related calls)\@chownChanging file ownership (L<chown(2)>, L<fchownat(2)>, and related calls)\@clockSystem calls for changing the system clock (L<adjtimex(2)>, L<settimeofday(2)>, and related calls)\@cpu-emulationSystem calls for CPU emulation functionality (L<vm86(2)> and related calls)\@debugDebugging, performance monitoring and tracing functionality (L<ptrace(2)>, L<perf_event_open(2)> and related calls)\@file-systemFile system operations: opening, creating files and directories for read and write, renaming and removing them, reading file properties, or creating hard and symbolic links\@io-eventEvent loop system calls (L<poll(2)>, L<select(2)>, L<epoll(7)>, L<eventfd(2)> and related calls)\@ipcPipes, SysV IPC, POSIX Message Queues and other IPC (L<mq_overview(7)>, L<svipc(7)>)\@keyringKernel keyring access (L<keyctl(2)> and related calls)\@memlockLocking of memory in RAM (L<mlock(2)>, L<mlockall(2)> and related calls)\@moduleLoading and unloading of kernel modules (L<init_module(2)>, L<delete_module(2)> and related calls)\@mountMounting and unmounting of file systems (L<mount(2)>, L<chroot(2)>, and related calls)\@network-ioSocket I/O (including local AF_UNIX): L<socket(7)>, L<unix(7)>\@obsoleteUnusual, obsolete or unimplemented (L<create_module(2)>, L<gtty(2)>, \x{2026})\@privilegedAll system calls which need super-user capabilities (L<capabilities(7)>)\@processProcess control, execution, namespacing operations (L<clone(2)>, L<kill(2)>, L<namespaces(7)>, \x{2026})\@raw-ioRaw I/O port access (L<ioperm(2)>, L<iopl(2)>, pciconfig_read(), \x{2026})\@rebootSystem calls for rebooting and reboot preparation (L<reboot(2)>, kexec(), \x{2026})\@resourcesSystem calls for changing resource limits, memory and scheduling parameters (L<setrlimit(2)>, L<setpriority(2)>, \x{2026})\@setuidSystem calls for changing user ID and group ID credentials, (L<setuid(2)>, L<setgid(2)>, L<setresuid(2)>, \x{2026})\@signalSystem calls for manipulating and handling process signals (L<signal(2)>, L<sigprocmask(2)>, \x{2026})\@swapSystem calls for enabling/disabling swap devices (L<swapon(2)>, L<swapoff(2)>)\@syncSynchronizing files and memory to disk (L<fsync(2)>, L<msync(2)>, and related calls)\@system-serviceA reasonable set of system calls used by common system services, excluding any special purpose calls. This is the recommended starting point for allow-listing system calls for system services, as it contains what is typically needed by system services, but excludes overly specific interfaces. For example, the following APIs are excluded: C<\@clock>, C<\@mount>, C<\@swap>, C<\@reboot>.\@timerSystem calls for scheduling operations by time (L<alarm(2)>, L<timer_create(2)>, \x{2026})\@knownAll system calls defined by the kernel. This list is defined statically in systemd based on a kernel version that was available when this systemd version was released. It will become progressively more out-of-date as the kernel is updated.
Note, that as new system calls are added to the kernel, additional system calls might be added to the groups
above. Contents of the sets may also change between systemd versions. In addition, the list of system calls
depends on the kernel version and architecture for which systemd was compiled. Use
systemd-analyze\x{a0}syscall-filter to list the actual list of system calls in each
filter.

Generally, allow-listing system calls (rather than deny-listing) is the safer mode of
operation. It is recommended to enforce system call allow lists for all long-running system
services. Specifically, the following lines are a relatively safe basic choice for the majority of
system services:

Note that various kernel system calls are defined redundantly: there are multiple system calls
for executing the same operation. For example, the pidfd_send_signal() system
call may be used to execute operations similar to what can be done with the older
kill() system call, hence blocking the latter without the former only provides
weak protection. Since new system calls are added regularly to the kernel as development progresses,
keeping system call deny lists comprehensive requires constant work. It is thus recommended to use
allow-listing instead, which offers the benefit that new system calls are by default implicitly
blocked until the allow list is updated.

Also note that a number of system calls are required to be accessible for the dynamic linker to
work. The dynamic linker is required for running most regular programs (specifically: all dynamic ELF
binaries, which is how most distributions build packaged programs). This means that blocking these
system calls (which include open(), openat() or
mmap()) will make most programs typically shipped with generic distributions
unusable.

It is recommended to combine the file system namespacing related options with
C<SystemCallFilter=~\@mount>, in order to prohibit the unit's processes to undo the
mappings. Specifically these are the options C<PrivateTmp>,
C<PrivateDevices>, C<ProtectSystem>, C<ProtectHome>,
C<ProtectKernelTunables>, C<ProtectControlGroups>,
C<ProtectKernelLogs>, C<ProtectClock>, C<ReadOnlyPaths>,
C<InaccessiblePaths> and C<ReadWritePaths>.",
        'type' => 'list'
      },
      'SystemCallErrorNumber',
      {
        'description' => 'Takes an C<errno> error number (between 1 and 4095) or errno name
such as C<EPERM>, C<EACCES> or C<EUCLEAN>, to
return when the system call filter configured with C<SystemCallFilter> is triggered,
instead of terminating the process immediately. See L<errno(3)> for a
full list of error codes. When this setting is not used, or when the empty string or the special
setting C<kill> is assigned, the process will be terminated immediately when the
filter is triggered.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SystemCallArchitectures',
      {
        'description' => "Takes a space-separated list of architecture identifiers to include in the system call
filter. The known architecture identifiers are the same as for C<ConditionArchitecture>
described in L<systemd.unit(5)>,
as well as C<x32>, C<mips64-n32>, C<mips64-le-n32>, and
the special identifier C<native>.  The special identifier C<native>
implicitly maps to the native architecture of the system (or more precisely: to the architecture the system
manager is compiled for). If running in user mode, or in system mode, but without the
C<CAP_SYS_ADMIN> capability (e.g. setting C<User>),
C<NoNewPrivileges=yes> is implied. By default, this option is set to the empty list, i.e. no
filtering is applied.

If this setting is used, processes of this unit will only be permitted to call native system calls, and
system calls of the specified architectures. For the purposes of this option, the x32 architecture is treated
as including x86-64 system calls. However, this setting still fulfills its purpose, as explained below, on
x32.

System call filtering is not equally effective on all architectures. For example, on x86
filtering of network socket-related calls is not possible, due to ABI limitations \x{2014} a limitation that x86-64
does not have, however. On systems supporting multiple ABIs at the same time \x{2014} such as x86/x86-64 \x{2014} it is hence
recommended to limit the set of permitted system call architectures so that secondary ABIs may not be used to
circumvent the restrictions applied to the native ABI of the system. In particular, setting
C<SystemCallArchitectures=native> is a good choice for disabling non-native ABIs.

System call architectures may also be restricted system-wide via the
C<SystemCallArchitectures> option in the global configuration. See
L<systemd-system.conf(5)> for
details.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SystemCallLog',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Takes a space-separated list of system call names. If this setting is used, all
system calls executed by the unit processes for the listed ones will be logged. If the first
character of the list is C<~>, the effect is inverted: all system calls except the
listed system calls will be logged. If running in user mode, or in system mode, but without the
C<CAP_SYS_ADMIN> capability (e.g. setting C<User>),
C<NoNewPrivileges=yes> is implied. This feature makes use of the Secure Computing
Mode 2 interfaces of the kernel (\'seccomp filtering\') and is useful for auditing or setting up a
minimal sandboxing environment. This option may be specified more than once, in which case the filter
masks are merged. If the empty string is assigned, the filter is reset, all prior assignments will
have no effect. This does not affect commands prefixed with C<+>.',
        'type' => 'list'
      },
      'Environment',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Sets environment variables for executed processes. Each line is unquoted using the
rules described in \"Quoting\" section in
L<systemd.syntax(7)>
and becomes a list of variable assignments. If you need to assign a value containing spaces or the
equals sign to a variable, put quotes around the whole assignment. Variable expansion is not
performed inside the strings and the C<\$> character has no special meaning. Specifier
expansion is performed, see the \"Specifiers\" section in
L<systemd.unit(5)>.

This option may be specified more than once, in which case all listed variables will be set. If
the same variable is listed twice, the later setting will override the earlier setting. If the empty
string is assigned to this option, the list of environment variables is reset, all prior assignments
have no effect.

The names of the variables can contain ASCII letters, digits, and the underscore character.
Variable names cannot be empty or start with a digit. In variable values, most characters are
allowed, but non-printable characters are currently rejected.

Example:

    Environment=\"VAR1=word1 word2\" VAR2=word3 \"VAR3=\$word 5 6\"

gives three variables C<VAR1>,
C<VAR2>, C<VAR3>
with the values C<word1 word2>,
C<word3>, C<\$word 5 6>.

See L<environ(7)> for
details about environment variables.

Note that environment variables are not suitable for passing secrets (such as passwords, key
material, \x{2026})  to service processes. Environment variables set for a unit are exposed to unprivileged
clients via D-Bus IPC, and generally not understood as being data that requires protection. Moreover,
environment variables are propagated down the process tree, including across security boundaries
(such as setuid/setgid executables), and hence might leak to processes that should not have access to
the secret data. Use C<LoadCredential> (see below) to pass data to unit processes
securely.",
        'type' => 'list'
      },
      'EnvironmentFile',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Similar to C<Environment> but reads the environment variables from a text
file. The text file should contain new-line-separated variable assignments.  Empty lines, lines without an
C<=> separator, or lines starting with ; or # will be ignored, which may be used for
commenting. A line ending with a backslash will be concatenated with the following one, allowing multiline
variable definitions. The parser strips leading and trailing whitespace from the values of assignments, unless
you use double quotes (").

L<C escapes|https://en.wikipedia.org/wiki/Escape_sequences_in_C#Table_of_escape_sequences>
are supported, but not
L<most control characters|https://en.wikipedia.org/wiki/Control_character#In_ASCII>.
C<\\t> and C<\\n> can be used to insert tabs and newlines within
C<EnvironmentFile>.

The argument passed should be an absolute filename or wildcard expression, optionally prefixed with
C<->, which indicates that if the file does not exist, it will not be read and no error or
warning message is logged. This option may be specified more than once in which case all specified files are
read. If the empty string is assigned to this option, the list of file to read is reset, all prior assignments
have no effect.

The files listed with this directive will be read shortly before the process is executed (more
specifically, after all processes from a previous unit state terminated.  This means you can generate these
files in one unit state, and read it with this option in the next.  The files are read from the file
system of the service manager, before any file system changes like bind mounts take place).

Settings from these files override settings made with C<Environment>. If the same
variable is set twice from these files, the files will be read in the order they are specified and the later
setting will override the earlier setting.',
        'type' => 'list'
      },
      'PassEnvironment',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Pass environment variables set for the system service manager to executed processes. Takes a
space-separated list of variable names. This option may be specified more than once, in which case all listed
variables will be passed. If the empty string is assigned to this option, the list of environment variables to
pass is reset, all prior assignments have no effect. Variables specified that are not set for the system
manager will not be passed and will be silently ignored. Note that this option is only relevant for the system
service manager, as system services by default do not automatically inherit any environment variables set for
the service manager itself. However, in case of the user service manager all environment variables are passed
to the executed processes anyway, hence this option is without effect for the user service manager.

Variables set for invoked processes due to this setting are subject to being overridden by those
configured with C<Environment> or C<EnvironmentFile>.

L<C escapes|https://en.wikipedia.org/wiki/Escape_sequences_in_C#Table_of_escape_sequences>
are supported, but not
L<most control characters|https://en.wikipedia.org/wiki/Control_character#In_ASCII>.
C<\\t> and C<\\n> can be used to insert tabs and newlines within
C<EnvironmentFile>.

Example:

    PassEnvironment=VAR1 VAR2 VAR3

passes three variables C<VAR1>,
C<VAR2>, C<VAR3>
with the values set for those variables in PID1.

See L<environ(7)> for details
about environment variables.',
        'type' => 'list'
      },
      'UnsetEnvironment',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Explicitly unset environment variable assignments that would normally be passed from the
service manager to invoked processes of this unit. Takes a space-separated list of variable names or variable
assignments. This option may be specified more than once, in which case all listed variables/assignments will
be unset. If the empty string is assigned to this option, the list of environment variables/assignments to
unset is reset. If a variable assignment is specified (that is: a variable name, followed by
C<=>, followed by its value), then any environment variable matching this precise assignment is
removed. If a variable name is specified (that is a variable name without any following C<=> or
value), then any assignment matching the variable name, regardless of its value is removed. Note that the
effect of C<UnsetEnvironment> is applied as final step when the environment list passed to
executed processes is compiled. That means it may undo assignments from any configuration source, including
assignments made through C<Environment> or C<EnvironmentFile>, inherited from
the system manager\'s global set of environment variables, inherited via C<PassEnvironment>,
set by the service manager itself (such as C<$NOTIFY_SOCKET> and such), or set by a PAM module
(in case C<PAMName> is used).

See "Environment Variables in Spawned Processes" below for a description of how those
settings combine to form the inherited environment. See L<environ(7)> for general
information about environment variables.',
        'type' => 'list'
      },
      'StandardInput',
      {
        'choice' => [
          'null',
          'tty',
          'tty-force',
          'tty-fail',
          'data',
          'socket'
        ],
        'description' => "Controls where file descriptor 0 (STDIN) of the executed processes is connected to. Takes one
of C<null>, C<tty>, C<tty-force>, C<tty-fail>,
C<data>, C<file:path>, C<socket> or
C<fd:name>.

If C<null> is selected, standard input will be connected to C</dev/null>,
i.e. all read attempts by the process will result in immediate EOF.

If C<tty> is selected, standard input is connected to a TTY (as configured by
C<TTYPath>, see below) and the executed process becomes the controlling process of the
terminal. If the terminal is already being controlled by another process, the executed process waits until the
current controlling process releases the terminal.

C<tty-force> is similar to C<tty>, but the executed process is forcefully and
immediately made the controlling process of the terminal, potentially removing previous controlling processes
from the terminal.

C<tty-fail> is similar to C<tty>, but if the terminal already has a
controlling process start-up of the executed process fails.

The C<data> option may be used to configure arbitrary textual or binary data to pass via
standard input to the executed process. The data to pass is configured via
C<StandardInputText>/C<StandardInputData> (see below). Note that the actual
file descriptor type passed (memory file, regular file, UNIX pipe, \x{2026}) might depend on the kernel and available
privileges. In any case, the file descriptor is read-only, and when read returns the specified data followed by
EOF.

The C<file:path> option may be used to connect a specific file
system object to standard input. An absolute path following the C<:> character is expected,
which may refer to a regular file, a FIFO or special file. If an C<AF_UNIX> socket in the
file system is specified, a stream socket is connected to it. The latter is useful for connecting standard
input of processes to arbitrary system services.

The C<socket> option is valid in socket-activated services only, and requires the relevant
socket unit file (see
L<systemd.socket(5)> for details)
to have C<Accept=yes> set, or to specify a single socket only. If this option is set, standard
input will be connected to the socket the service was activated from, which is primarily useful for
compatibility with daemons designed for use with the traditional L<inetd(8)> socket activation
daemon.

The C<fd:name> option connects standard input to a specific,
named file descriptor provided by a socket unit.  The name may be specified as part of this option, following a
C<:> character (e.g. C<fd:foobar>).  If no name is specified, the name
C<stdin> is implied (i.e. C<fd> is equivalent to C<fd:stdin>).
At least one socket unit defining the specified name must be provided via the C<Sockets>
option, and the file descriptor name may differ from the name of its containing socket unit.  If multiple
matches are found, the first one will be used.  See C<FileDescriptorName> in
L<systemd.socket(5)> for more
details about named file descriptors and their ordering.

This setting defaults to C<null>, unless
C<StandardInputText>/C<StandardInputData> are set, in which case it
defaults to C<data>.",
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'StandardOutput',
      {
        'choice' => [
          'inherit',
          'null',
          'tty',
          'journal',
          'kmsg',
          'journal+console',
          'kmsg+console',
          'socket'
        ],
        'description' => 'Controls where file descriptor 1 (stdout) of the executed processes is connected
to. Takes one of C<inherit>, C<null>, C<tty>,
C<journal>, C<kmsg>, C<journal+console>,
C<kmsg+console>, C<file:path>,
C<append:path>, C<truncate:path>,
C<socket> or C<fd:name>.

C<inherit> duplicates the file descriptor of standard input for standard output.

C<null> connects standard output to C</dev/null>, i.e. everything written
to it will be lost.

C<tty> connects standard output to a tty (as configured via C<TTYPath>,
see below). If the TTY is used for output only, the executed process will not become the controlling process of
the terminal, and will not fail or wait for other processes to release the terminal.

C<journal> connects standard output with the journal, which is accessible via
L<journalctl(1)>. Note
that everything that is written to kmsg (see below) is implicitly stored in the journal as well, the
specific option listed below is hence a superset of this one. (Also note that any external,
additional syslog daemons receive their log data from the journal, too, hence this is the option to
use when logging shall be processed with such a daemon.)

C<kmsg> connects standard output with the kernel log buffer which is accessible via
L<dmesg(1)>,
in addition to the journal. The journal daemon might be configured to send all logs to kmsg anyway, in which
case this option is no different from C<journal>.

C<journal+console> and C<kmsg+console> work in a similar way as the
two options above but copy the output to the system console as well.

The C<file:path> option may be used to connect a specific file
system object to standard output. The semantics are similar to the same option of
C<StandardInput>, see above. If path refers to a regular file
on the filesystem, it is opened (created if it doesn\'t exist yet) for writing at the beginning of the file,
but without truncating it.
If standard input and output are directed to the same file path, it is opened only once, for reading as well
as writing and duplicated. This is particularly useful when the specified path refers to an
C<AF_UNIX> socket in the file system, as in that case only a
single stream connection is created for both input and output.

C<append:path> is similar to
C<file:path> above, but it opens the file in append mode.

C<truncate:path> is similar to
C<file:path> above, but it truncates the file when opening
it. For units with multiple command lines, e.g. C<Type=oneshot> services with
multiple C<ExecStart>, or services with C<ExecCondition>,
C<ExecStartPre> or C<ExecStartPost>, the output file is reopened
and therefore re-truncated for each command line. If the output file is truncated while another
process still has the file open, e.g. by an C<ExecReload> running concurrently with
an C<ExecStart>, and the other process continues writing to the file without
adjusting its offset, then the space between the file pointers of the two processes may be filled
with C<NUL> bytes, producing a sparse file. Thus,
C<truncate:path> is typically only useful for units where
only one process runs at a time, such as services with a single C<ExecStart> and no
C<ExecStartPost>, C<ExecReload>, C<ExecStop> or
similar.

C<socket> connects standard output to a socket acquired via socket activation. The
semantics are similar to the same option of C<StandardInput>, see above.

The C<fd:name> option connects standard output to a specific,
named file descriptor provided by a socket unit.  A name may be specified as part of this option, following a
C<:> character (e.g. C<fd:foobar>).  If no name is specified, the name
C<stdout> is implied (i.e. C<fd> is equivalent to
C<fd:stdout>).  At least one socket unit defining the specified name must be provided via the
C<Sockets> option, and the file descriptor name may differ from the name of its containing
socket unit.  If multiple matches are found, the first one will be used.  See
C<FileDescriptorName> in
L<systemd.socket(5)> for more
details about named descriptors and their ordering.

If the standard output (or error output, see below) of a unit is connected to the journal or
the kernel log buffer, the unit will implicitly gain a dependency of type C<After>
on C<systemd-journald.socket> (also see the "Implicit Dependencies" section
above). Also note that in this case stdout (or stderr, see below) will be an
C<AF_UNIX> stream socket, and not a pipe or FIFO that can be re-opened. This means
when executing shell scripts the construct echo "hello" > /dev/stderr for
writing text to stderr will not work. To mitigate this use the construct echo "hello"
>&2 instead, which is mostly equivalent and avoids this pitfall.

This setting defaults to the value set with C<DefaultStandardOutput> in
L<systemd-system.conf(5)>, which
defaults to C<journal>. Note that setting this parameter might result in additional dependencies
to be added to the unit (see above).',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'StandardError',
      {
        'description' => 'Controls where file descriptor 2 (stderr) of the executed processes is connected to. The
available options are identical to those of C<StandardOutput>, with some exceptions: if set to
C<inherit> the file descriptor used for standard output is duplicated for standard error, while
C<fd:name> will use a default file descriptor name of
C<stderr>.

This setting defaults to the value set with C<DefaultStandardError> in
L<systemd-system.conf(5)>, which
defaults to C<inherit>. Note that setting this parameter might result in additional dependencies
to be added to the unit (see above).',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StandardInputText',
      {
        'description' => 'Configures arbitrary textual or binary data to pass via file descriptor 0 (STDIN) to
the executed processes. These settings have no effect unless C<StandardInput> is set
to C<data> (which is the default if C<StandardInput> is not set
otherwise, but C<StandardInputText>/C<StandardInputData> is). Use
this option to embed process input data directly in the unit file.

C<StandardInputText> accepts arbitrary textual data. C-style escapes for special
characters as well as the usual C<%>-specifiers are resolved. Each time this setting is used
the specified text is appended to the per-unit data buffer, followed by a newline character (thus every use
appends a new line to the end of the buffer). Note that leading and trailing whitespace of lines configured
with this option is removed. If an empty line is specified the buffer is cleared (hence, in order to insert an
empty line, add an additional C<\\n> to the end or beginning of a line).

C<StandardInputData> accepts arbitrary binary data, encoded in L<Base64|https://tools.ietf.org/html/rfc2045#section-6.8>. No escape sequences or specifiers are
resolved. Any whitespace in the encoded version is ignored during decoding.

Note that C<StandardInputText> and C<StandardInputData> operate on the
same data buffer, and may be mixed in order to configure both binary and textual data for the same input
stream. The textual or binary data is joined strictly in the order the settings appear in the unit
file. Assigning an empty string to either will reset the data buffer.

Please keep in mind that in order to maintain readability long unit file settings may be split into
multiple lines, by suffixing each line (except for the last) with a C<\\> character (see
L<systemd.unit(5)> for
details). This is particularly useful for large data configured with these two options. Example:',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StandardInputData',
      {
        'description' => 'Configures arbitrary textual or binary data to pass via file descriptor 0 (STDIN) to
the executed processes. These settings have no effect unless C<StandardInput> is set
to C<data> (which is the default if C<StandardInput> is not set
otherwise, but C<StandardInputText>/C<StandardInputData> is). Use
this option to embed process input data directly in the unit file.

C<StandardInputText> accepts arbitrary textual data. C-style escapes for special
characters as well as the usual C<%>-specifiers are resolved. Each time this setting is used
the specified text is appended to the per-unit data buffer, followed by a newline character (thus every use
appends a new line to the end of the buffer). Note that leading and trailing whitespace of lines configured
with this option is removed. If an empty line is specified the buffer is cleared (hence, in order to insert an
empty line, add an additional C<\\n> to the end or beginning of a line).

C<StandardInputData> accepts arbitrary binary data, encoded in L<Base64|https://tools.ietf.org/html/rfc2045#section-6.8>. No escape sequences or specifiers are
resolved. Any whitespace in the encoded version is ignored during decoding.

Note that C<StandardInputText> and C<StandardInputData> operate on the
same data buffer, and may be mixed in order to configure both binary and textual data for the same input
stream. The textual or binary data is joined strictly in the order the settings appear in the unit
file. Assigning an empty string to either will reset the data buffer.

Please keep in mind that in order to maintain readability long unit file settings may be split into
multiple lines, by suffixing each line (except for the last) with a C<\\> character (see
L<systemd.unit(5)> for
details). This is particularly useful for large data configured with these two options. Example:',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LogLevelMax',
      {
        'description' => 'Configures filtering by log level of log messages generated by this unit. Takes a
syslog log level, one of C<emerg> (lowest log level, only highest priority
messages), C<alert>, C<crit>, C<err>, C<warning>,
C<notice>, C<info>, C<debug> (highest log level, also lowest priority
messages). See L<syslog(3)> for
details. By default no filtering is applied (i.e. the default maximum log level is C<debug>). Use
this option to configure the logging system to drop log messages of a specific service above the specified
level. For example, set C<LogLevelMax>C<info> in order to turn off debug logging
of a particularly chatty unit. Note that the configured level is applied to any log messages written by any
of the processes belonging to this unit, as well as any log messages written by the system manager process
(PID 1) in reference to this unit, sent via any supported logging protocol. The filtering is applied
early in the logging pipeline, before any kind of further processing is done. Moreover, messages which pass
through this filter successfully might still be dropped by filters applied at a later stage in the logging
subsystem. For example, C<MaxLevelStore> configured in
L<journald.conf(5)> might
prohibit messages of higher log levels to be stored on disk, even though the per-unit
C<LogLevelMax> permitted it to be processed.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LogExtraFields',
      {
        'description' => 'Configures additional log metadata fields to include in all log records generated by
processes associated with this unit. This setting takes one or more journal field assignments in the
format C<FIELD=VALUE> separated by whitespace. See
L<systemd.journal-fields(7)>
for details on the journal field concept. Even though the underlying journal implementation permits
binary field values, this setting accepts only valid UTF-8 values. To include space characters in a
journal field value, enclose the assignment in double quotes (").
The usual specifiers are expanded in all assignments (see below). Note that this setting is not only
useful for attaching additional metadata to log records of a unit, but given that all fields and
values are indexed may also be used to implement cross-unit log record matching. Assign an empty
string to reset the list.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LogRateLimitIntervalSec',
      {
        'description' => 'Configures the rate limiting that is applied to messages generated by this unit. If, in the
time interval defined by C<LogRateLimitIntervalSec>, more messages than specified in
C<LogRateLimitBurst> are logged by a service, all further messages within the interval are
dropped until the interval is over. A message about the number of dropped messages is generated. The time
specification for C<LogRateLimitIntervalSec> may be specified in the following units: "s",
"min", "h", "ms", "us" (see
L<systemd.time(7)> for details).
The default settings are set by C<RateLimitIntervalSec> and C<RateLimitBurst>
configured in L<journald.conf(5)>.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LogRateLimitBurst',
      {
        'description' => 'Configures the rate limiting that is applied to messages generated by this unit. If, in the
time interval defined by C<LogRateLimitIntervalSec>, more messages than specified in
C<LogRateLimitBurst> are logged by a service, all further messages within the interval are
dropped until the interval is over. A message about the number of dropped messages is generated. The time
specification for C<LogRateLimitIntervalSec> may be specified in the following units: "s",
"min", "h", "ms", "us" (see
L<systemd.time(7)> for details).
The default settings are set by C<RateLimitIntervalSec> and C<RateLimitBurst>
configured in L<journald.conf(5)>.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LogNamespace',
      {
        'description' => 'Run the unit\'s processes in the specified journal namespace. Expects a short
user-defined string identifying the namespace. If not used the processes of the service are run in
the default journal namespace, i.e. their log stream is collected and processed by
C<systemd-journald.service>. If this option is used any log data generated by
processes of this unit (regardless if via the syslog(), journal native logging
or stdout/stderr logging) is collected and processed by an instance of the
C<systemd-journald@.service> template unit, which manages the specified
namespace. The log data is stored in a data store independent from the default log namespace\'s data
store. See
L<systemd-journald.service(8)>
for details about journal namespaces.

Internally, journal namespaces are implemented through Linux mount namespacing and
over-mounting the directory that contains the relevant C<AF_UNIX> sockets used for
logging in the unit\'s mount namespace. Since mount namespaces are used this setting disconnects
propagation of mounts from the unit\'s processes to the host, similar to how
C<ReadOnlyPaths> and similar settings (see above) work. Journal namespaces may hence
not be used for services that need to establish mount points on the host.

When this option is used the unit will automatically gain ordering and requirement dependencies
on the two socket units associated with the C<systemd-journald@.service> instance
so that they are automatically established prior to the unit starting up. Note that when this option
is used log output of this service does not appear in the regular
L<journalctl(1)>
output, unless the C<--namespace=> option is used.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SyslogIdentifier',
      {
        'description' => 'Sets the process name ("syslog tag") to prefix log lines sent to
the logging system or the kernel log buffer with. If not set, defaults to the process name of the
executed process.  This option is only useful when C<StandardOutput> or
C<StandardError> are set to C<journal> or C<kmsg> (or to
the same settings in combination with C<+console>) and only applies to log messages
written to stdout or stderr.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SyslogFacility',
      {
        'description' => 'Sets the syslog facility identifier to use when logging. One of
C<kern>, C<user>, C<mail>, C<daemon>,
C<auth>, C<syslog>, C<lpr>, C<news>,
C<uucp>, C<cron>, C<authpriv>, C<ftp>,
C<local0>, C<local1>, C<local2>, C<local3>,
C<local4>, C<local5>, C<local6> or
C<local7>. See L<syslog(3)> for
details. This option is only useful when C<StandardOutput> or
C<StandardError> are set to C<journal> or C<kmsg> (or to
the same settings in combination with C<+console>), and only applies to log messages
written to stdout or stderr. Defaults to C<daemon>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SyslogLevel',
      {
        'description' => 'The default syslog log level to use when logging to the logging system or
the kernel log buffer. One of C<emerg>, C<alert>, C<crit>,
C<err>, C<warning>, C<notice>, C<info>,
C<debug>. See L<syslog(3)> for
details. This option is only useful when C<StandardOutput> or
C<StandardError> are set to C<journal> or
C<kmsg> (or to the same settings in combination with C<+console>), and only applies
to log messages written to stdout or stderr. Note that individual lines output by executed processes may be
prefixed with a different log level which can be used to override the default log level specified here. The
interpretation of these prefixes may be disabled with C<SyslogLevelPrefix>, see below. For
details, see L<sd-daemon(3)>.
Defaults to C<info>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SyslogLevelPrefix',
      {
        'description' => 'Takes a boolean argument. If true and C<StandardOutput> or
C<StandardError> are set to C<journal> or C<kmsg> (or to
the same settings in combination with C<+console>), log lines written by the executed
process that are prefixed with a log level will be processed with this log level set but the prefix
removed. If set to false, the interpretation of these prefixes is disabled and the logged lines are
passed on as-is. This only applies to log messages written to stdout or stderr. For details about
this prefixing see
L<sd-daemon(3)>.
Defaults to true.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'TTYPath',
      {
        'description' => 'Sets the terminal device node to use if standard input, output, or error are connected to a TTY
(see above). Defaults to C</dev/console>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TTYReset',
      {
        'description' => 'Reset the terminal device specified with C<TTYPath> before and after
execution.  Defaults to C<no>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TTYVHangup',
      {
        'description' => 'Disconnect all clients which have opened the terminal device specified with
C<TTYPath> before and after execution. Defaults to C<no>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TTYVTDisallocate',
      {
        'description' => 'If the terminal device specified with C<TTYPath> is a virtual console
terminal, try to deallocate the TTY before and after execution. This ensures that the screen and scrollback
buffer is cleared. Defaults to C<no>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LoadCredential',
      {
        'description' => 'Pass a credential to the unit. Credentials are limited-size binary or textual objects
that may be passed to unit processes. They are primarily used for passing cryptographic keys (both
public and private) or certificates, user account information or identity information from host to
services. The data is accessible from the unit\'s processes via the file system, at a read-only
location that (if possible and permitted) is backed by non-swappable memory. The data is only
accessible to the user associated with the unit, via the
C<User>/C<DynamicUser> settings (as well as the superuser). When
available, the location of credentials is exported as the C<$CREDENTIALS_DIRECTORY>
environment variable to the unit\'s processes.

The C<LoadCredential> setting takes a textual ID to use as name for a
credential plus a file system path, separated by a colon. The ID must be a short ASCII string
suitable as filename in the filesystem, and may be chosen freely by the user. If the specified path
is absolute it is opened as regular file and the credential data is read from it. If the absolute
path refers to an C<AF_UNIX> stream socket in the file system a connection is made
to it (only once at unit start-up) and the credential data read from the connection, providing an
easy IPC integration point for dynamically providing credentials from other services. If the
specified path is not absolute and itself qualifies as valid credential identifier it is understood
to refer to a credential that the service manager itself received via the
C<$CREDENTIALS_DIRECTORY> environment variable, which may be used to propagate
credentials from an invoking environment (e.g. a container manager that invoked the service manager)
into a service. The contents of the file/socket may be arbitrary binary or textual data, including
newline characters and C<NUL> bytes. If the file system path is omitted it is
chosen identical to the credential name, i.e. this is a terse way do declare credentials to inherit
from the service manager into a service. This option may be used multiple times, each time defining
an additional credential to pass to the unit.

The credential files/IPC sockets must be accessible to the service manager, but don\'t have to
be directly accessible to the unit\'s processes: the credential data is read and copied into separate,
read-only copies for the unit that are accessible to appropriately privileged processes. This is
particularly useful in combination with C<DynamicUser> as this way privileged data
can be made available to processes running under a dynamic UID (i.e. not a previously known one)
without having to open up access to all users.

In order to reference the path a credential may be read from within a
C<ExecStart> command line use C<${CREDENTIALS_DIRECTORY}/mycred>,
e.g. C<ExecStart=cat ${CREDENTIALS_DIRECTORY}/mycred>.

Currently, an accumulated credential size limit of 1 MB per unit is enforced.

If referencing an C<AF_UNIX> stream socket to connect to, the connection will
originate from an abstract namespace socket, that includes information about the unit and the
credential ID in its socket name. Use L<getpeername(2)>
to query this information. The returned socket name is formatted as C<NUL>RANDOM C</unit/> UNITC</> ID, i.e. a C<NUL> byte (as required
for abstract namespace socket names), followed by a random string (consisting of alphadecimal
characters), followed by the literal string C</unit/>, followed by the requesting
unit name, followed by the literal character C</>, followed by the textual credential
ID requested. Example: C<\\0adf9d86b6eda275e/unit/foobar.service/credx> in case the
credential C<credx> is requested for a unit C<foobar.service>. This
functionality is useful for using a single listening socket to serve credentials to multiple
consumers.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SetCredential',
      {
        'description' => 'The C<SetCredential> setting is similar to
C<LoadCredential> but accepts a literal value to use as data for the credential,
instead of a file system path to read the data from. Do not use this option for data that is supposed
to be secret, as it is accessible to unprivileged processes via IPC. It\'s only safe to use this for
user IDs, public key material and similar non-sensitive data. For everything else use
C<LoadCredential>. In order to embed binary data into the credential data use
C-style escaping (i.e. C<\\n> to embed a newline, or C<\\x00> to embed
a C<NUL> byte).

If a credential of the same ID is listed in both C<LoadCredential> and
C<SetCredential>, the latter will act as default if the former cannot be
retrieved. In this case not being able to retrieve the credential from the path specified in
C<LoadCredential> is not considered fatal.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UtmpIdentifier',
      {
        'description' => 'Takes a four character identifier string for an L<utmp(5)> and wtmp entry
for this service. This should only be set for services such as getty implementations (such
as L<agetty(8)>) where utmp/wtmp
entries must be created and cleared before and after execution, or for services that shall be executed as if
they were run by a getty process (see below). If the configured string is longer than four
characters, it is truncated and the terminal four characters are used. This setting interprets %I style string
replacements. This setting is unset by default, i.e. no utmp/wtmp entries are created or cleaned up for this
service.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UtmpMode',
      {
        'choice' => [
          'init',
          'login',
          'user'
        ],
        'description' => 'Takes one of C<init>, C<login> or C<user>. If
C<UtmpIdentifier> is set, controls which type of L<utmp(5)>/wtmp entries
for this service are generated. This setting has no effect unless C<UtmpIdentifier> is set
too. If C<init> is set, only an C<INIT_PROCESS> entry is generated and the
invoked process must implement a getty-compatible utmp/wtmp logic. If
C<login> is set, first an C<INIT_PROCESS> entry, followed by a
C<LOGIN_PROCESS> entry is generated. In this case, the invoked process must implement a
L<login(1)>-compatible
utmp/wtmp logic. If C<user> is set, first an C<INIT_PROCESS> entry, then a
C<LOGIN_PROCESS> entry and finally a C<USER_PROCESS> entry is
generated. In this case, the invoked process may be any process that is suitable to be run as session
leader. Defaults to C<init>.',
        'type' => 'leaf',
        'value_type' => 'enum'
      }
    ],
    'generated_by' => 'parse-man.pl from systemd 249 doc',
    'license' => 'LGPLv2.1+',
    'name' => 'Systemd::Common::Exec'
  }
]
;

