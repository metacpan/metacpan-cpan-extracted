#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'author' => [
      'Dominique Dumont'
    ],
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'element' => [
      'lazy_itable_init',
      {
        'description' => 'If enabled and the uninit_bg feature is enabled, the inode table will not be fully initialized by mke2fs. This speeds up filesystem initialization noticeably, but it requires the kernel to finish initializing the filesystem in the background when the filesystem is first mounted.',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      }
    ],
    'include' => [
      'Fstab::Ext2FsOpt'
    ],
    'license' => 'LGPL2',
    'name' => 'Fstab::Ext4FsOpt'
  }
]
;

