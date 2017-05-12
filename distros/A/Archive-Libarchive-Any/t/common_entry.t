use strict;
use warnings;
use Test::More tests => 52;
use Archive::Libarchive::Any qw( :all );

my $r;

my $e = archive_entry_new();
ok $e, 'archive_entry_new';

is archive_entry_pathname($e), undef, 'archive_entry_pathname = undef';

$r = archive_entry_set_pathname($e, 'hi.txt');
is $r, ARCHIVE_OK, 'archive_entry_set_pathname';

is archive_entry_pathname($e), 'hi.txt', 'archive_entry_pathname = hi.txt';

is eval { archive_entry_mode($e) }, 0, 'archive_entry_mode (0)';
diag $@ if $@;

$r = eval { archive_entry_set_mode($e, 0644) };
diag $@ if $@;
is $r, ARCHIVE_OK, 'archive_entry_set_mode';

is eval { archive_entry_mode($e) }, 0644, 'archive_entry_mode (0644)';
diag $@ if $@;

SKIP: { 
  skip 'test requires archive_entry_perm', 1 unless Archive::Libarchive::Any->can('archive_entry_perm');
  is eval { archive_entry_perm($e) }, 0644, 'archive_entry_perm(0644)';
  diag $@ if $@;
};

$r = eval { archive_entry_set_filetype($e, AE_IFREG) };
diag $@ if $@;
is $r, ARCHIVE_OK, 'archive_entry_set_filetype';

is eval { archive_entry_filetype($e) }, AE_IFREG, 'archive_entry_filetype';
diag $@ if $@;

is eval { archive_entry_strmode($e) }, '-rw-r--r-- ', 'archive_entry_strmode';
diag $@ if $@;

is archive_entry_uid($e), 0, 'archive_entry_uid = 0';
$r = archive_entry_set_uid($e, 101);
is $r, ARCHIVE_OK, 'archive_entry_set_uid';
is archive_entry_uid($e), 101, 'archive_entry_uid = 101';

is eval { archive_entry_gid($e) }, 0, 'archive_entry_gid = 0';
diag $@ if $@;
$r = eval { archive_entry_set_gid($e, 201) };
diag $@ if $@;
is $r, ARCHIVE_OK, 'archive_entry_set_gid';
is eval { archive_entry_gid($e) }, 201, 'archive_entry_gid = 201';
diag $@ if $@;

$r = archive_entry_set_nlink($e, 5);
is $r, ARCHIVE_OK, 'archive_entry_set_nlink';

is eval { archive_entry_nlink($e) }, 5, 'archive_entry_nlink';
diag $@ if $@;

SKIP: {
  skip 'requires archive_entry_dev_is_set', 1 unless Archive::Libarchive::Any->can('archive_entry_dev_is_set');
  ok !archive_entry_dev_is_set($e), 'archive_entry_dev_is_set';
};
$r = archive_entry_set_devmajor($e, 0x24);
is $r, ARCHIVE_OK, 'archive_entry_devmajor';
is archive_entry_devmajor($e), 0x24, 'archive_entry_devmajor';
$r = archive_entry_set_devminor($e, 0x67);
is $r, ARCHIVE_OK, 'archive_entry_set_devminor';
is archive_entry_devminor($e), 0x67, 'archive_entry_devminor';
#is sprintf("%x", archive_entry_dev($e)), sprintf("%x", 0x2467), 'archive_entry_dev';
SKIP: {
  skip 'requires archive_entry_dev_is_set', 1 unless Archive::Libarchive::Any->can('archive_entry_dev_is_set');
  ok archive_entry_dev_is_set($e), 'archive_entry_dev_is_set';
};

$r = archive_entry_set_dev($e, 0x1234);
is $r, ARCHIVE_OK, 'archive_entry_set_dev';
is archive_entry_dev($e), 0x1234, 'archive_entry_dev';

SKIP: {
  skip 'archive_entry_ino_is_set', 1 unless Archive::Libarchive::Any->can('archive_entry_ino_is_set');
  ok !eval { archive_entry_ino_is_set($e) }, 'archive_entry_ino_is_set';
  diag $@ if $@;
};
$r = archive_entry_set_ino($e, 0x12);
is $r, ARCHIVE_OK, 'archive_entry_set_ino';
is archive_entry_ino($e), 0x12, 'archive_entry_ino';
SKIP: {
  skip 'archive_entry_ino_is_set', 1 unless Archive::Libarchive::Any->can('archive_entry_ino_is_set');
  ok eval { archive_entry_ino_is_set($e) }, 'archive_entry_ino_is_set';
  diag $@ if $@;
};

$r = archive_entry_set_rdevmajor($e, 0x24);
is $r, ARCHIVE_OK, 'archive_entry_rdevmajor';
is archive_entry_rdevmajor($e), 0x24, 'archive_entry_rdevmajor';
$r = archive_entry_set_rdevminor($e, 0x67);
is $r, ARCHIVE_OK, 'archive_entry_set_rdevminor';
is archive_entry_rdevminor($e), 0x67, 'archive_entry_rdevminor';
#is sprintf("%x", archive_entry_rdev($e)), sprintf("%x", 0x2467), 'archive_entry_rdev';

$r = archive_entry_set_rdev($e, 0x1234);
is $r, ARCHIVE_OK, 'archive_entry_set_rdev';
is archive_entry_rdev($e), 0x1234, 'archive_entry_rdev';

$r = eval { archive_entry_set_atime($e, 123456789, 123456789) };
diag $@ if $@;
is $r, ARCHIVE_OK, 'archive_entry_set_atime';
is eval { archive_entry_atime($e) }, 123456789, 'archive_entry_atime';
diag $@ if $@;
is eval { archive_entry_atime_nsec($e) }, 123456789, 'archive_entry_atime_nsec';
diag $@ if $@;

$r = eval { archive_entry_set_mtime($e, 123456798, 123456798) };
diag $@ if $@;
is $r, ARCHIVE_OK, 'archive_entry_set_mtime';
is eval { archive_entry_mtime($e) }, 123456798, 'archive_entry_mtime';
diag $@ if $@;
is eval { archive_entry_mtime_nsec($e) }, 123456798, 'archive_entry_mtime_nsec';
diag $@ if $@;

$r = eval { archive_entry_set_ctime($e, 123456766, 123456766) };
diag $@ if $@;
is $r, ARCHIVE_OK, 'archive_entry_set_ctime';
is eval { archive_entry_ctime($e) }, 123456766, 'archive_entry_ctime';
diag $@ if $@;
is eval { archive_entry_ctime_nsec($e) }, 123456766, 'archive_entry_ctime_nsec';
diag $@ if $@;

$r = eval { archive_entry_set_sourcepath($e, "foo") };
diag $@ if $@;
is $r, ARCHIVE_OK, 'archive_entry_set_sourcepath';
is eval { archive_entry_sourcepath($e) }, 'foo', 'archive_entry_set_sourcepath';
diag $@ if $@;

subtest fflags => sub {
  plan tests => 5;

  $r = archive_entry_set_fflags($e, 0x55, 0xaa);
  is $r, ARCHIVE_OK, 'archive_entry_set_fflags';

  $r = archive_entry_fflags($e, my $set, my $clear);
  is $r, ARCHIVE_OK, 'archive_entry_fflags';
  
  is $set, 0x55, 'set';
  is $clear, 0xaa, 'clear';
  
  subtest fflags_text => sub {
    plan skip_all => 'converting fflags bitmap ot string is system-dependent (test requires FreeBSD)'
      unless $^O eq 'freebsd';
    plan tests => 5;

    my $fflags = archive_entry_fflags_text($e);
    is $fflags, 'uappnd,nouchg,nodump,noopaque,uunlnk', 'archive_entry_fflags_text';
    
    $r = eval { archive_entry_set_fflags_text($e, " ,nouappnd, nouchg, dump,uunlnk") };
    diag $@ if $@;
    is $r, ARCHIVE_OK, 'archive_entry_set_fflags_text';
    
    $r = archive_entry_fflags($e, $set, $clear);
    is $r, ARCHIVE_OK, 'archive_entry_fflags';
    is $set, 16, 'set';
    is $clear, 7, 'clear';
  };
};  

subtest link => sub {
  plan skip_all => 'requires archive_entry_set_hardlink'
    unless Archive::Libarchive::Any->can('archive_entry_set_hardlink');
  plan tests => 7;
  
  $r = archive_entry_set_hardlink($e, "hardlinkname");
  is $r, ARCHIVE_OK, 'archive_entry_set_hardlink hardlinkname';
  $r = archive_entry_set_symlink($e, undef);
  is $r, ARCHIVE_OK, 'archive_entry_set_symlink undef';

  is archive_entry_hardlink($e), "hardlinkname", 'archive_entry_hardlink = hardlinkname';
  is archive_entry_symlink($e), undef, 'archive_entry_symlink = undef';

  $r = eval { archive_entry_set_link($e, "link") };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_entry_set_link';
  
  is archive_entry_hardlink($e), "link", 'archive_entry_hardlink = link';
  is archive_entry_symlink($e), undef, 'archive_entry_symlink = undef';
};

subtest xattr => sub {
  plan tests => 24;
  $r = archive_entry_xattr_add_entry($e, "xattr1", "xattrvalue1\0");
  is $r, ARCHIVE_OK, 'archive_entry_xattr_add_entry';
    
  is archive_entry_xattr_reset($e), 1, 'archive_entry_xattr_reset';
    
  $r = archive_entry_xattr_next($e, my $xname, my $xval);
  is $r, ARCHIVE_OK, 'archive_entry_xattr_next';
   
  is $xname, 'xattr1',        'xname = xattr1';
  is $xval,  "xattrvalue1\0", 'xval  = xattrvaue1';
  is length $xval, 12,        'len   = 12';
  
  is archive_entry_xattr_count($e), 1, 'archive_entry_xattr_count';
    
  $r = archive_entry_xattr_next($e, $xname, $xval);
  is $r, ARCHIVE_WARN, 'archive_entry_xattr_next';
  is $xname, undef,       'xname = undef';
  is $xval, undef,        'xval  = undef';
    
  $r = archive_entry_xattr_clear($e);
  is $r, ARCHIVE_OK, 'archive_entry_xattr_clear';
    
  is archive_entry_xattr_reset($e), 0, 'archive_entry_xattr_reset';
    
  $r = archive_entry_xattr_next($e, $xname, $xval);
  is $r, ARCHIVE_WARN, 'archive_entry_xattr_next';
  is $xname, undef,       'xname = undef';
  is $xval, undef,        'xval  = undef';

  $r = archive_entry_xattr_add_entry($e, "xattr1", "xattrvalue1\0");
  is $r, ARCHIVE_OK, 'archive_entry_xattr_add_entry';
  is archive_entry_xattr_reset($e), 1, 'archive_entry_xattr_reset';
  $r = archive_entry_xattr_add_entry($e, "xattr2", "xattrvalue2\0");
  is $r, ARCHIVE_OK, 'archive_entry_xattr_add_entry';
  is archive_entry_xattr_reset($e), 2, 'archive_entry_xattr_reset';

  $r = archive_entry_xattr_next($e, $xname, $xval);
  is $r, ARCHIVE_OK, 'archive_entry_xattr_next';
  $r = archive_entry_xattr_next($e, $xname, $xval);
  is $r, ARCHIVE_OK, 'archive_entry_xattr_next';
  $r = archive_entry_xattr_next($e, $xname, $xval);

  is $r, ARCHIVE_WARN, 'archive_entry_xattr_next';
  is $xname, undef,       'xname = undef';
  is $xval, undef,        'xval  = undef';
};

$r = archive_entry_free($e);
is $r, ARCHIVE_OK, 'archive_entry_free';
