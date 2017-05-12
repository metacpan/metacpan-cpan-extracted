use strict;
use warnings;
use Test::More tests => 2;
use Archive::Libarchive::Any qw( :all );

subtest 'archive_entry_stat' => sub {
  plan tests => 10;

  my $entry = archive_entry_new();
  
  archive_entry_set_dev($entry, 0x1234);
  archive_entry_set_ino($entry, 0x5678);
  archive_entry_set_mode($entry, 0400);
  archive_entry_set_nlink($entry, 1);
  archive_entry_set_uid($entry, 500);
  archive_entry_set_gid($entry, 501);
  archive_entry_set_rdev($entry, 0x1357);
  archive_entry_set_atime($entry, 123456789, 123456789);
  archive_entry_set_mtime($entry, 123456779, 123456779);
  archive_entry_set_ctime($entry, 123456769, 123456769);

  my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $atime, $mtime, $ctime) = eval { archive_entry_stat($entry) };
  diag $@ if $@;
  
  is $dev,   0x1234,    'dev';
  is $ino,   0x5678,    'ino';
  is $mode,  0400,      'mode';
  is $nlink, 1,         'nlink';
  is $uid,   500,       'uid';
  is $gid,   501,       'gid';
  is $rdev,  0x1357,    'rdev';
  is $atime, 123456789, 'atime';
  is $mtime, 123456779, 'mtime';
  is $ctime, 123456769, 'ctime';

  archive_entry_free($entry);
  
};

subtest 'archive_entry_set_stat' => sub {
  plan tests => 10;

  my $entry = archive_entry_new();
  
  eval { archive_entry_set_stat($entry,0x1234,0x5678,0400,1,500,501,0x1357,123456789,123456779,123456769) };
  diag $@ if $@;
  
  my $dev   = archive_entry_dev($entry);
  my $ino   = archive_entry_ino($entry);
  my $mode  = archive_entry_mode($entry);
  my $nlink = archive_entry_nlink($entry);
  my $uid   = archive_entry_uid($entry);
  my $gid   = archive_entry_gid($entry);
  my $rdev  = archive_entry_rdev($entry);
  my $atime = archive_entry_atime($entry);
  my $mtime = archive_entry_mtime($entry);
  my $ctime = archive_entry_ctime($entry);

  is $dev,   0x1234,    'dev';
  is $ino,   0x5678,    'ino';
  is $mode,  0400,      'mode';
  is $nlink, 1,         'nlink';
  is $uid,   500,       'uid';
  is $gid,   501,       'gid';
  is $rdev,  0x1357,    'rdev';
  is $atime, 123456789, 'atime';
  is $mtime, 123456779, 'mtime';
  is $ctime, 123456769, 'ctime';

  archive_entry_free($entry);
  
};

