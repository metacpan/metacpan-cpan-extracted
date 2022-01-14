class:Fstab
  class_description="static information about the filesystems. fstab contains descriptive information about the various file systems. 
"
  license=LGPL2
  author:="Dominique Dumont"
  copyright:="2010,2011 Dominique Dumont"
  element:fs
    type=hash
    summary="specification of one file system"
    description="Each \"fs\" element contain the information about one filesystem. Each filesystem is referred in this model by a label constructed by the fstab parser. This label cannot be stored in the fstab file, so if you create a new file system, the label you will choose may not be stored and will be re-created by the fstab parser"
    index_type=string
    cargo
      type=node
      config_class_name=Fstab::FsLine - -
  rw_config
    backend=Fstab
    config_dir=/etc
    file=fstab - -
class:Fstab::CommonOptions
  class_description="options valid for all types of file systems."
  license=LGPL2
  author:="Dominique Dumont"
  copyright:="2010,2011 Dominique Dumont"
  element:async
    type=leaf
    value_type=boolean
    description="All I/O to the filesystem should be done asynchronously. (See also the sync option.)
" -
  element:atime
    type=leaf
    value_type=boolean
    description="Do not use the noatime feature, so the inode access time is controlled by kernel defaults. See also the descriptions of the relatime and strictatime mount options." -
  element:auto
    type=leaf
    value_type=boolean
    description="Can be mounted with the -a option of C<mount> command" -
  element:dev
    type=leaf
    value_type=boolean
    description="Interpret character or block special devices on the filesystem." -
  element:exec
    type=leaf
    value_type=boolean
    description="Permit execution of binaries." -
  element:suid
    type=leaf
    value_type=boolean
    description="Honor set-user-ID and set-group-ID bits or file capabilities when executing programs from this filesystem." -
  element:group
    type=leaf
    value_type=boolean
    description="Allow an ordinary user to mount the filesystem if one of that user’s groups matches the group of the device. This option implies the options nosuid and nodev (unless overridden by subsequent options, as in the option line group,dev,suid)." -
  element:mand
    type=leaf
    value_type=boolean
    description="Allow mandatory locks on this filesystem. See L<fcntl(2)>." -
  element:user
    type=leaf
    value_type=boolean
    help:0="Only root can mount the file system"
    help:1="user can mount the file system"
    description="Allow an ordinary user to mount the filesystem. The name of the mounting user is written to the mtab file (or to the private libmount file in /run/mount on systems without a regular mtab) so that this same user can unmount the filesystem again. This option implies the options noexec, nosuid, and nodev (unless overridden by subsequent options, as in the option line user,exec,dev,suid)." -
  element:defaults
    type=leaf
    value_type=boolean
    help:1="option equivalent to rw, suid, dev, exec, auto, nouser, and async"
    description="Use the default options: rw, suid, dev, exec, auto, nouser, and async.

Note that the real set of all default mount options depends on the kernel and filesystem type. See the beginning of this section for more details." -
  element:rw
    type=leaf
    value_type=boolean
    help:0="read-only file system"
    description="Mount the filesystem read-write." -
  element:relatime
    type=leaf
    value_type=boolean
    description="Update inode access times relative to modify or change time. Access time is only updated if the previous access time was earlier than the current modify or change time. (Similar to noatime, but it doesn’t break mutt(1) or other applications that need to know if a file has been read since the last time it was modified.)" -
  element:umask
    type=leaf
    value_type=uniline
    description="Set the umask (the bitmask of the permissions that are not present). The default is the umask of the current process. The value is given in octal." - -
class:Fstab::Ext2FsOpt
  license=LGPL2
  author:="Dominique Dumont"
  copyright:="2010,2011 Dominique Dumont"
  element:acl
    type=leaf
    value_type=boolean -
  element:user_xattr
    type=leaf
    value_type=boolean
    description="Support \"user.\" extended attributes " -
  element:statfs_behavior
    type=leaf
    value_type=enum
    choice:=bsddf,minixdf -
  element:errors
    type=leaf
    value_type=enum
    choice:=continue,remount-ro,panic -
  include:=Fstab::CommonOptions
  accept:".*"
    type=leaf
    value_type=uniline
    description="unknown parameter" - -
class:Fstab::Ext3FsOpt
  class_description="Options for ext4 file systems. Please contact author (domi.dumont at cpan.org) if options are missing."
  license=LGPL2
  author:="Dominique Dumont"
  copyright:="2010,2011 Dominique Dumont"
  element:journalling_mode
    type=leaf
    value_type=enum
    choice:=journal,ordered,writeback
    help:journal="All data is committed into the journal prior to being written into the main file system. "
    help:ordered="This is the default mode. All data is forced directly out to the main file system prior to its metadata being committed to the journal."
    help:writeback="Data ordering is not preserved - data may be writteninto the main file system after its metadata has been committed to the journal. This is rumoured to be the highest-throughput option. It guarantees internal file system integrity, however it can allow old data to appear in files after a crash and journal recovery."
    description="Specifies the journalling mode for file data. Metadata is always journaled. To use modes other than ordered on the root file system, pass the mode to the kernel as boot parameter, e.g. rootflags=data=journal." -
  include:=Fstab::Ext2FsOpt -
class:Fstab::Ext4FsOpt
  license=LGPL2
  author:="Dominique Dumont"
  copyright:="2010,2011 Dominique Dumont"
  element:lazy_itable_init
    type=leaf
    value_type=boolean
    upstream_default=1
    description="If enabled and the uninit_bg feature is enabled, the inode table will not be fully initialized by mke2fs. This speeds up filesystem initialization noticeably, but it requires the kernel to finish initializing the filesystem in the background when the filesystem is first mounted." -
  include:=Fstab::Ext2FsOpt -
class:Fstab::FsLine
  class_description="data of one /etc/fstab line"
  license=LGPL2
  gist="{fs_vfstype}: {fs_file}"
  author:="Dominique Dumont"
  copyright:="2010,2011 Dominique Dumont"
  element:fs_spec
    type=leaf
    value_type=uniline
    mandatory=1
    description="block special device or remote filesystem to be mounted"
    warp
      follow:f1="- fs_vfstype"
      rules:"$f1 eq 'proc'"
        default=proc - - -
  element:fs_file
    type=leaf
    value_type=uniline
    mandatory=1
    description="mount point for the filesystem"
    warp
      follow:f1="- fs_vfstype"
      rules:"$f1 eq 'proc'"
        default=/proc -
      rules:"$f1 eq 'swap'"
        default=none - - -
  element:fs_vfstype
    type=leaf
    value_type=enum
    mandatory=1
    choice:=auto,davfs,ext2,ext3,ext4,swap,proc,iso9660,vfat,usbfs,ignore,nfs,nfs4,none,ignore,debugfs
    help:auto="file system type is probed by the kernel when mounting the device"
    help:davfs="WebDav access"
    help:ext2="Common Linux file system."
    help:ext3="Common Linux file system with journaling "
    help:ignore="unused disk partition"
    help:iso9660="CD-ROM or DVD file system"
    help:proc="Kernel info through a special file system"
    help:usbfs="USB pseudo file system. Gives a file system view of kernel data related to usb"
    help:vfat="Older Windows file system often used on removable media"
    description="file system type" -
  element:fs_mntopts
    type=warped_node
    description="mount options associated with the filesystem"
    warp
      follow:f1="- fs_vfstype"
      rules:"$f1 eq 'proc'"
        config_class_name=Fstab::CommonOptions -
      rules:"$f1 eq 'auto'"
        config_class_name=Fstab::CommonOptions -
      rules:"$f1 eq 'vfat'"
        config_class_name=Fstab::CommonOptions -
      rules:"$f1 eq 'swap'"
        config_class_name=Fstab::SwapOptions -
      rules:"$f1 eq 'ext2'"
        config_class_name=Fstab::Ext2FsOpt -
      rules:"$f1 eq 'ext3'"
        config_class_name=Fstab::Ext3FsOpt -
      rules:"$f1 eq 'ext4'"
        config_class_name=Fstab::Ext4FsOpt -
      rules:"$f1 eq 'usbfs'"
        config_class_name=Fstab::UsbFsOptions -
      rules:"$f1 eq 'davfs'"
        config_class_name=Fstab::CommonOptions -
      rules:"$f1 eq 'iso9660'"
        config_class_name=Fstab::Iso9660_Opt -
      rules:"$f1 eq 'nfs'"
        config_class_name=Fstab::CommonOptions -
      rules:"$f1 eq 'nfs4'"
        config_class_name=Fstab::CommonOptions -
      rules:"$f1 eq 'none'"
        config_class_name=Fstab::NoneOptions -
      rules:"$f1 eq 'debugfs'"
        config_class_name=Fstab::CommonOptions - - -
  element:fs_freq
    type=leaf
    value_type=enum
    choice:=0,1
    default=0
    description="Specifies if the file system needs to be dumped"
    warp
      follow:fstyp="- fs_vfstype"
      follow:isbound="- fs_mntopts bind"
      rules:"$fstyp eq \"none\" and $isbound"
        choice:=0 - - -
  element:fs_passno
    type=leaf
    value_type=integer
    default=0
    summary="fsck pass number"
    description="used by the fsck(8) program to determine the order in which filesystem checks are done at reboot time"
    warp
      follow:fstyp="- fs_vfstype"
      follow:isbound="- fs_mntopts bind"
      rules:"$fstyp eq \"none\" and $isbound"
        max=0 - - - -
class:Fstab::Iso9660_Opt
  license=LGPL2
  author:="Dominique Dumont"
  copyright:="2010,2011 Dominique Dumont"
  element:rock
    type=leaf
    value_type=boolean -
  element:joliet
    type=leaf
    value_type=boolean -
  include:=Fstab::CommonOptions -
class:Fstab::NoneOptions
  class_description="Options for special file system like 'bind'"
  license=LGPL2
  author:="Dominique Dumont"
  copyright:="2010,2011 Dominique Dumont"
  element:bind
    type=leaf
    value_type=boolean - -
class:Fstab::SwapOptions
  class_description="Swap options"
  license=LGPL2
  author:="Dominique Dumont"
  copyright:="2010,2011 Dominique Dumont"
  element:sw
    type=leaf
    value_type=boolean - -
class:Fstab::UsbFsOptions
  class_description="usbfs options"
  license=LGPL2
  author:="Dominique Dumont"
  copyright:="2010,2011 Dominique Dumont"
  element:devuid
    type=leaf
    value_type=integer
    upstream_default=0 -
  element:devgid
    type=leaf
    value_type=integer
    upstream_default=0 -
  element:busuid
    type=leaf
    value_type=integer
    upstream_default=0 -
  element:budgid
    type=leaf
    value_type=integer
    upstream_default=0 -
  element:listuid
    type=leaf
    value_type=integer
    upstream_default=0 -
  element:listgid
    type=leaf
    value_type=integer
    upstream_default=0 -
  element:devmode
    type=leaf
    value_type=integer
    upstream_default=0644 -
  element:busmode
    type=leaf
    value_type=integer
    upstream_default=0555 -
  element:listmode
    type=leaf
    value_type=integer
    upstream_default=0444 -
  include:=Fstab::CommonOptions -
application:fstab
  model=Fstab
  category=system - -
